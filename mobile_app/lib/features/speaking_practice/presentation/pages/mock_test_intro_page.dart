import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../domain/usecases/get_questions_by_topic_usecase.dart';
import '../bloc/speaking_bloc.dart';
import 'cue_card_session_page.dart';
import 'full_mock_simulation_page.dart';

class MockTestIntroPage extends StatelessWidget {
  const MockTestIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('IELTS Speaking Simulation', style: AppTextStyles.h3),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card (Solid Royal Blue - NO GRADIENTS)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.primaryCard,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '11 - 14 MINUTES COMPLETE EXAM',
                        style: AppTextStyles.label.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Official IELTS Speaking Simulation',
                      style: AppTextStyles.h2.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Experience an authentic test environment with native voice prompts, timed cue card delivery, and deep Part 3 discussion.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text('Test Structure', style: AppTextStyles.h3),
              const SizedBox(height: 12),

              _buildTestPartTile(
                partNumber: '1',
                title: 'Introduction & Interview',
                duration: '4 - 5 Minutes',
                description: 'General questions regarding your work, studies, hometown, and everyday hobbies.',
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: AppColors.tealIcon,
                iconBgColor: AppColors.tealIconBg,
              ),
              const SizedBox(height: 12),
              _buildTestPartTile(
                partNumber: '2',
                title: 'Candidate Long Turn (Cue Card)',
                duration: '3 - 4 Minutes',
                description: '1 minute note-taking preparation, followed by a sustained 2-minute speech on a given topic.',
                icon: Icons.timer_outlined,
                iconColor: AppColors.purple,
                iconBgColor: AppColors.purpleSoft,
              ),
              const SizedBox(height: 12),
              _buildTestPartTile(
                partNumber: '3',
                title: 'Two-Way Abstract Discussion',
                duration: '4 - 5 Minutes',
                description: 'In-depth, analytical questions exploring broader societal themes connected to Part 2.',
                icon: Icons.forum_outlined,
                iconColor: AppColors.orange,
                iconBgColor: AppColors.orangeSoft,
              ),

              const SizedBox(height: 24),

              Text('Examiner Assessment Criteria', style: AppTextStyles.h3),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceBorderLight, width: 1.5),
                ),
                child: Column(
                  children: [
                    _buildCriteriaRow('Fluency & Coherence (25%)', 'Smooth rhythm, natural pause placement, linking words.'),
                    const Divider(height: 18),
                    _buildCriteriaRow('Lexical Resource (25%)', 'Precise topic vocabulary, collocations, idiomatic control.'),
                    const Divider(height: 18),
                    _buildCriteriaRow('Grammar Range & Accuracy (25%)', 'Complex sentences, conditionals, tense accuracy.'),
                    const Divider(height: 18),
                    _buildCriteriaRow('Pronunciation (25%)', 'Word stress, intonation, sentence melody, clear vowels.'),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              BlocBuilder<SpeakingBloc, SpeakingState>(
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow_rounded, size: 22),
                      label: const Text('Start Full IELTS Speaking Mock Test'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        if (state is SpeakingLoaded && state.cueCards.isNotEmpty && state.allTopics.isNotEmpty) {
                          final firstTopic = state.allTopics.first;
                          final getQuestions = sl<GetQuestionsByTopicUseCase>();
                          final res = await getQuestions(firstTopic.id);
                          
                          if (!context.mounted) return;
                          
                          res.fold(
                            (failure) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CueCardSessionPage(cueCard: state.cueCards.first),
                                ),
                              );
                            },
                            (questions) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FullMockSimulationPage(
                                    cueCard: state.cueCards.first,
                                    part1Questions: questions,
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Preparing exam materials...')),
                          );
                        }
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestPartTile({
    required String partNumber,
    required String title,
    required String duration,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorderLight, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PART $partNumber', style: AppTextStyles.label.copyWith(color: iconColor)),
                    Text(duration, style: AppTextStyles.bodySmall),
                  ],
                ),
                const SizedBox(height: 3),
                Text(title, style: AppTextStyles.titleMedium),
                const SizedBox(height: 3),
                Text(description, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaRow(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.teal),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(desc, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
