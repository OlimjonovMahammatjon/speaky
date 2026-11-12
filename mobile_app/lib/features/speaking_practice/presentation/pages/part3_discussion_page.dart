import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/cue_card_entity.dart';
import '../widgets/question_audio_recorder_widget.dart';

class Part3DiscussionPage extends StatefulWidget {
  final CueCardEntity cueCard;

  const Part3DiscussionPage({super.key, required this.cueCard});

  @override
  State<Part3DiscussionPage> createState() => _Part3DiscussionPageState();
}

class _Part3DiscussionPageState extends State<Part3DiscussionPage> {
  int _currentQuestionIndex = 0;
  final Set<int> _revealedAnswers = {};
  int _elapsedSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followUps = widget.cueCard.part3FollowUps;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Part 3: Discussion', style: AppTextStyles.h3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            _stopTimer();
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Timer bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: AppColors.primarySoft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DISCUSSION TIME',
                    style: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                  ),
                  Text(
                    _formatDuration(_elapsedSeconds),
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.primaryDark,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),

            // Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Answer with extended, analytical responses (30–60 seconds each).',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ),

            // Questions list
            Expanded(
              child: followUps.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      itemCount: followUps.length,
                      itemBuilder: (context, index) {
                        return _buildQuestionCard(
                          index: index,
                          question: followUps[index],
                        );
                      },
                    ),
            ),

            // Bottom navigation
            if (followUps.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(color: AppColors.surfaceBorderLight, width: 1.5),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentQuestionIndex > 0)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentQuestionIndex--;
                          });
                        },
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Previous'),
                      )
                    else
                      const SizedBox(width: 100),
                    Text(
                      '${_currentQuestionIndex + 1} / ${followUps.length}',
                      style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
                    ),
                    if (_currentQuestionIndex < followUps.length - 1)
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentQuestionIndex++;
                          });
                        },
                        icon: const Text('Next'),
                        label: const Icon(Icons.arrow_forward, size: 18),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          _stopTimer();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Finish'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.forum_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No Part 3 questions available', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              'Part 3 follow-up questions will appear here when the cue card includes them.',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard({
    required int index,
    required String question,
  }) {
    final isCurrent = index == _currentQuestionIndex;
    final isRevealed = _revealedAnswers.contains(index);

    if (!isCurrent) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _currentQuestionIndex = index;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorderLight, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'QUESTION ${index + 1} OF ${widget.cueCard.part3FollowUps.length}',
                style: AppTextStyles.label.copyWith(color: AppColors.primaryDark, fontSize: 10),
              ),
            ),
            const SizedBox(height: 12),

            // Question text
            Text(
              question,
              style: AppTextStyles.titleMedium.copyWith(height: 1.4),
            ),
            const SizedBox(height: 16),

            // Strategy tips
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
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
                  Text('STRATEGY TIP', style: AppTextStyles.label.copyWith(color: AppColors.primary, fontSize: 10.5)),
                  const SizedBox(height: 6),
                  Text(
                    _getStrategyTip(index),
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Per-Question Audio Recorder
            QuestionAudioRecorderWidget(
              key: ValueKey('part3_q_$index'),
              questionId: 'part3_q_$index',
              label: 'Record answer to question ${index + 1}',
            ),
            const SizedBox(height: 14),

            // Show/Hide model approach
            GestureDetector(
              onTap: () {
                setState(() {
                  if (isRevealed) {
                    _revealedAnswers.remove(index);
                  } else {
                    _revealedAnswers.add(index);
                  }
                });
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isRevealed ? 'Hide answer approach' : 'Show answer approach',
                  style: AppTextStyles.label.copyWith(color: AppColors.primaryDark),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            if (isRevealed) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Model Answer Approach', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 8),
                    ..._getModelApproach(index).map((point) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: AppColors.primary)),
                              Expanded(
                                child: Text(point, style: AppTextStyles.bodySmall.copyWith(height: 1.4)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Key vocabulary reminder
            if (widget.cueCard.keyCollocations.isNotEmpty) ...[
              Text('Useful Collocations from Part 2:', style: AppTextStyles.label),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: widget.cueCard.keyCollocations.take(3).map((colloc) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.purpleSoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      colloc,
                      style: TextStyle(
                        color: AppColors.purple,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStrategyTip(int index) {
    final tips = [
      'Structure your answer: state your opinion directly, then provide 1-2 concrete reasons with examples.',
      'Use comparative language (whereas, in contrast, on the other hand) to show nuanced thinking.',
      'Connect to broader societal trends — examiners reward answers that go beyond personal experience.',
    ];
    return tips[index % tips.length];
  }

  List<String> _getModelApproach(int index) {
    final approaches = [
      [
        'Start with a clear stance: "I firmly believe that..." or "It depends on the context..."',
        'Provide a real-world example or hypothetical scenario to illustrate your point.',
        'Conclude with a balanced summary: "Ultimately, while X is true, Y must also be considered."',
      ],
      [
        'Acknowledge both sides before stating your position.',
        'Use hedging language: "It could be argued that...", "One might say..."',
        'Draw from cultural or generational differences to add depth.',
      ],
      [
        'Begin with a broad observation about societal trends.',
        'Narrow down to a specific example from your country or experience.',
        'End with a forward-looking statement about potential changes.',
      ],
    ];
    return approaches[index % approaches.length];
  }
}
