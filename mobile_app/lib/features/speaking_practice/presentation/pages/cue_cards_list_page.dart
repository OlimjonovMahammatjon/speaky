import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/cue_card_entity.dart';
import '../bloc/speaking_bloc.dart';
import '../widgets/band_score_badge.dart';
import 'cue_card_session_page.dart';

class CueCardsListPage extends StatefulWidget {
  const CueCardsListPage({super.key});

  @override
  State<CueCardsListPage> createState() => _CueCardsListPageState();
}

class _CueCardsListPageState extends State<CueCardsListPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Part 2: Speak for Two Minutes', style: AppTextStyles.h3),
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<SpeakingBloc, SpeakingState>(
          builder: (context, state) {
            if (state is SpeakingLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (state is SpeakingLoaded) {
              final cards = state.cueCards.where((c) {
                if (_search.isEmpty) return true;
                return c.title.toLowerCase().contains(_search.toLowerCase()) ||
                    c.cuePrompt.toLowerCase().contains(_search.toLowerCase()) ||
                    c.topicArea.toLowerCase().contains(_search.toLowerCase());
              }).toList();

              return Column(
                children: [
                  // Search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search cue cards by title or topic...',
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
                          _search = val;
                        });
                      },
                    ),
                  ),

                  // Subtitle / Format line
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '1 minute preparation • 2 minutes speaking recording',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  // Cards List with pull-to-refresh
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        context.read<SpeakingBloc>().add(const LoadSpeakingDataEvent());
                      },
                      child: cards.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: 240,
                                  child: Center(
                                    child: Text('No cue cards found', style: AppTextStyles.bodyMedium),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              itemCount: cards.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final card = cards[index];
                                return _buildCardItem(context, card);
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
                      Text('Failed to load cue cards', style: AppTextStyles.h2),
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

  Widget _buildCardItem(BuildContext context, CueCardEntity card) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    card.topicArea,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const BandScoreBadge(scoreText: 'Band 8.0+'),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.only(left: 8),
                      icon: Icon(
                        card.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: card.isBookmarked ? AppColors.primary : AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () {
                        context.read<SpeakingBloc>().add(
                              ToggleCueCardBookmarkEvent(
                                cueCardId: card.id,
                                currentStatus: card.isBookmarked,
                              ),
                            );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(card.title, style: AppTextStyles.titleMedium.copyWith(fontSize: 16)),
            const SizedBox(height: 6),
            Text(
              card.cuePrompt,
              style: AppTextStyles.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (card.shortSampleAnswer.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  card.shortSampleAnswer,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(height: 12),

            // Collocations teaser chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: card.keyCollocations.take(3).map((colloc) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    colloc,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Clean Indigo Start Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CueCardSessionPage(cueCard: card),
                    ),
                  );
                },
                child: const Text('Start 1-Min Prep & Speak'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
