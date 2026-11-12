import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/topic_entity.dart';
import '../../domain/entities/question_entity.dart';
import '../../domain/usecases/get_questions_by_topic_usecase.dart';
import '../../../../injection_container.dart';
import '../bloc/speaking_bloc.dart';
import '../widgets/band_score_badge.dart';
import '../widgets/question_audio_recorder_widget.dart';

class Part1TopicsPage extends StatefulWidget {
  const Part1TopicsPage({super.key});

  @override
  State<Part1TopicsPage> createState() => _Part1TopicsPageState();
}

class _Part1TopicsPageState extends State<Part1TopicsPage> {
  final List<String> categories = [
    'All',
    'Technology',
    'WorkAndStudy',
    'TravelAndPlaces',
    'Environment',
    'ArtAndCulture',
  ];

  String _searchQuery = '';

  String _formatCategoryLabel(TopicCategory category) {
    switch (category) {
      case TopicCategory.technology:
        return 'Technology';
      case TopicCategory.workAndStudy:
        return 'Work & Study';
      case TopicCategory.travelAndPlaces:
        return 'Travel & Places';
      case TopicCategory.environment:
        return 'Environment';
      case TopicCategory.artAndCulture:
        return 'Art & Culture';
      case TopicCategory.societyAndPeople:
        return 'Society & People';
      case TopicCategory.hobbiesAndLifestyle:
        return 'Hobbies & Lifestyle';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Part 1: Quick Conversations', style: AppTextStyles.h3),
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<SpeakingBloc, SpeakingState>(
          builder: (context, state) {
            if (state is SpeakingLoading) {
              return const Center(child: CircularProgressIndicator(color: AppColors.primary));
            }

            if (state is SpeakingLoaded) {
              final topics = state.filteredTopics.where((t) {
                if (_searchQuery.isEmpty) return true;
                return t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    t.description.toLowerCase().contains(_searchQuery.toLowerCase());
              }).toList();

              return Column(
                children: [
                  // Search Field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search IELTS speaking topics...',
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
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = state.selectedCategory == cat;
                        final displayLabel = cat == 'WorkAndStudy'
                            ? 'Work & Study'
                            : cat == 'TravelAndPlaces'
                                ? 'Places'
                                : cat == 'ArtAndCulture'
                                    ? 'Art & Music'
                                    : cat;

                        return ChoiceChip(
                          label: Text(displayLabel),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              context.read<SpeakingBloc>().add(FilterTopicsByCategoryEvent(cat));
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

                  // Topic List with Pull-to-Refresh
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        context.read<SpeakingBloc>().add(const LoadSpeakingDataEvent());
                      },
                      child: topics.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height: 240,
                                  child: Center(
                                    child: Text(
                                      'No topics found',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              itemCount: topics.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final topic = topics[index];
                                return _buildTopicCard(context, topic);
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
                      Text('Failed to load topics', style: AppTextStyles.h2),
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

  Widget _buildTopicCard(BuildContext context, TopicEntity topic) {
    final categoryLabel = _formatCategoryLabel(topic.category).toUpperCase();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openTopicQuestionsBottomSheet(context, topic),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        categoryLabel,
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryDark,
                          fontSize: 10,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        BandScoreBadge(scoreText: topic.bandTarget),
                        const SizedBox(width: 6),
                        IconButton(
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            topic.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: topic.isBookmarked ? AppColors.primary : AppColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () {
                            context.read<SpeakingBloc>().add(
                                  ToggleTopicBookmarkEvent(
                                    topicId: topic.id,
                                    currentStatus: topic.isBookmarked,
                                  ),
                                );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(topic.title, style: AppTextStyles.titleLarge),
                const SizedBox(height: 4),
                Text(
                  topic.description,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${topic.questionsCount} Questions',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Practice',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTopicQuestionsBottomSheet(BuildContext context, TopicEntity topic) async {
    final getQuestionsUseCase = sl<GetQuestionsByTopicUseCase>();
    final result = await getQuestionsUseCase(GetQuestionsByTopicParams(topicId: topic.id));

    if (!context.mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (questions) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) {
            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return _TopicQuestionsSheetContent(
                  topic: topic,
                  questions: questions,
                  scrollController: scrollController,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _TopicQuestionsSheetContent extends StatefulWidget {
  final TopicEntity topic;
  final List<QuestionEntity> questions;
  final ScrollController scrollController;

  const _TopicQuestionsSheetContent({
    required this.topic,
    required this.questions,
    required this.scrollController,
  });

  @override
  State<_TopicQuestionsSheetContent> createState() => _TopicQuestionsSheetContentState();
}

class _TopicQuestionsSheetContentState extends State<_TopicQuestionsSheetContent> {
  final Map<String, bool> _expandedAnswers = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.surfaceBorder,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(widget.topic.title, style: AppTextStyles.h2),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: widget.questions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No questions added to this topic yet.',
                      style: AppTextStyles.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : ListView.separated(
                  controller: widget.scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: widget.questions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final q = widget.questions[index];
                    final isExpanded = _expandedAnswers[q.id] ?? false;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.surfaceBorder, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    'Q${index + 1}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  q.questionText,
                                  style: AppTextStyles.titleMedium.copyWith(height: 1.4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Brainstorming Ideas
                          if (q.ideas.isNotEmpty)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundSecondary,
                                borderRadius: BorderRadius.circular(12),
                                border: const Border(
                                  left: BorderSide(color: AppColors.primary, width: 3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'KEY IDEAS',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ...q.ideas.map((idea) => Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                                        Expanded(
                                          child: Text(
                                            idea,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 12.5,
                                              height: 1.35,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),

                          // Short Sample Answer
                          if (q.shortSampleAnswer.isNotEmpty)
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'QUICK SAMPLE ANSWER',
                                    style: TextStyle(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    q.shortSampleAnswer,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      height: 1.4,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Examiner Tip
                          if (q.examinerTips.isNotEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.backgroundSecondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'EXAMINER TIP',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10.5,
                                      letterSpacing: 0.7,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    q.examinerTips.first,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 12.5,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Practice Voice Recording for this specific question
                          QuestionAudioRecorderWidget(
                            key: ValueKey('topic_q_${q.id}'),
                            questionId: 'topic_${q.id}',
                            label: 'Record your answer (Q${index + 1})',
                          ),

                          const SizedBox(height: 14),

                          // Toggle Sample Answer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _expandedAnswers[q.id] = !isExpanded;
                                  });
                                },
                                child: Text(
                                  isExpanded ? 'Hide Band 8.5 Answer' : 'Show Band 8.5 Answer',
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const BandScoreBadge(scoreText: 'Band 8.5'),
                            ],
                          ),

                    if (isExpanded) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              q.sampleAnswerBand8,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'High-Band Vocabulary Used:',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: q.highBandVocabulary.map((word) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.surfaceBorder),
                                  ),
                                  child: Text(
                                    word,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
