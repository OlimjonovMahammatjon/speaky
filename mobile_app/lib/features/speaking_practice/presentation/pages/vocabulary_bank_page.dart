import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/vocabulary_entity.dart';
import '../bloc/speaking_bloc.dart';

class VocabularyBankPage extends StatefulWidget {
  const VocabularyBankPage({super.key});

  @override
  State<VocabularyBankPage> createState() => _VocabularyBankPageState();
}

class _VocabularyBankPageState extends State<VocabularyBankPage> {
  String _selectedType = 'All';
  String _searchQuery = '';

  final List<String> _typeFilters = ['All', 'Collocation', 'Idiom', 'DiscourseMarker', 'AcademicLexis'];

  String _formatTypeLabel(VocabularyType type) {
    switch (type) {
      case VocabularyType.collocation:
        return 'COLLOCATION';
      case VocabularyType.idiom:
        return 'IDIOM';
      case VocabularyType.discourseMarker:
        return 'DISCOURSE MARKER';
      case VocabularyType.academicLexis:
        return 'ACADEMIC LEXIS';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Band 8+ Vocabulary Bank', style: AppTextStyles.h3),
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<SpeakingBloc, SpeakingState>(
          builder: (context, state) {
            if (state is SpeakingLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (state is SpeakingLoaded) {
              final items = state.vocabularyItems.where((v) {
                final matchesType = _selectedType == 'All' || v.type.name.toLowerCase() == _selectedType.toLowerCase();
                final matchesSearch = _searchQuery.isEmpty ||
                    v.phrase.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    v.meaning.toLowerCase().contains(_searchQuery.toLowerCase());
                return matchesType && matchesSearch;
              }).toList();

              return Column(
                children: [
                  // Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search idioms, collocations, linking words...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.surfaceBorderLight, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.surfaceBorderLight, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                    ),
                  ),

                  // Category Pills
                  SizedBox(
                    height: 50,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      scrollDirection: Axis.horizontal,
                      itemCount: _typeFilters.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final type = _typeFilters[index];
                        final isSelected = _selectedType == type;
                        final displayLabel = type == 'DiscourseMarker'
                            ? 'Discourse Markers'
                            : type == 'AcademicLexis'
                                ? 'Academic Lexis'
                                : type;

                        return ChoiceChip(
                          label: Text(displayLabel),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedType = type;
                              });
                            }
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.surfaceBorderLight,
                              width: 1.5,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Vocabulary List with Pull-to-Refresh
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        context.read<SpeakingBloc>().add(const LoadSpeakingDataEvent());
                      },
                      child: items.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: 240,
                                  child: Center(
                                    child: Text('No vocabulary items found', style: AppTextStyles.bodyMedium),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: items.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = items[index];
                                return _buildVocabCard(item);
                              },
                            ),
                    ),
                  ),
                ],
              );
            }

            if (state is SpeakingError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text('Failed to load vocabulary', style: AppTextStyles.h2),
                      const SizedBox(height: 8),
                      Text(state.message, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                        onPressed: () {
                          context.read<SpeakingBloc>().add(const LoadSpeakingDataEvent());
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.hourglass_empty, size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('No data available', style: AppTextStyles.bodyMedium),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVocabCard(VocabularyEntity item) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.phrase,
                  style: AppTextStyles.titleLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.bandTarget,
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (item.phonetics.isNotEmpty) ...[
                Text(
                  item.phonetics,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _formatTypeLabel(item.type),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.meaning,
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(10),
              border: const Border(
                left: BorderSide(color: AppColors.primary, width: 3),
              ),
            ),
            child: Text(
              '"${item.exampleIeltsContext}"',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12.5,
                height: 1.45,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
