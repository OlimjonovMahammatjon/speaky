import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/cue_card_entity.dart';
import '../bloc/mock_test_bloc.dart';
import '../widgets/audio_wave_visualizer.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/cue_card_box.dart';
import '../widgets/criteria_score_card.dart';
import '../widgets/recorded_audio_player_widget.dart';
import 'part3_discussion_page.dart';

class CueCardSessionPage extends StatefulWidget {
  final CueCardEntity cueCard;

  const CueCardSessionPage({super.key, required this.cueCard});

  @override
  State<CueCardSessionPage> createState() => _CueCardSessionPageState();
}

class _CueCardSessionPageState extends State<CueCardSessionPage> {
  @override
  void initState() {
    super.initState();
    context.read<MockTestBloc>().add(StartCueCardSessionEvent(widget.cueCard));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Part 2: Cue Card Session', style: AppTextStyles.h3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            context.read<MockTestBloc>().add(const ResetSessionEvent());
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<MockTestBloc, MockTestState>(
          listener: (context, state) {
            if (state is MockTestResultState) {
              // Show notification when test result is ready
              sl<NotificationService>().showTestCompletedNotification(
                state.evaluation.overallBand,
              );
            }
          },
          builder: (context, state) {
            if (state is CueCardPreparingState) {
              return _buildPreparingView(context, state);
            } else if (state is CueCardSpeakingState) {
              return _buildSpeakingView(context, state);
            } else if (state is MockTestAnalyzingState) {
              return _buildAnalyzingView(state);
            } else if (state is MockTestResultState) {
              return _buildResultView(context, state);
            }
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          },
        ),
      ),
    );
  }

  Widget _buildPreparingView(BuildContext context, CueCardPreparingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Timer Widget
          CountdownTimerWidget(
            remainingSeconds: state.remainingSeconds,
            totalSeconds: state.totalSeconds,
            label: 'Preparation Time',
            isSpeaking: false,
          ),
          const SizedBox(height: 16),

          // Instructions Callout
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Read the prompts carefully and organize your 4 bullet points before speaking starts.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Cue Card Box
          CueCardBox(cueCard: state.cueCard),

          const SizedBox(height: 24),

          // Quick Action to Skip Prep and Speak Immediately
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.mic_rounded, color: Colors.white),
              label: const Text("I'm Ready! Start Speaking Now"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                context.read<MockTestBloc>().add(const SkipPrepToSpeakingEvent());
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSpeakingView(BuildContext context, CueCardSpeakingState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Speaking countdown timer
          CountdownTimerWidget(
            remainingSeconds: state.remainingSeconds,
            totalSeconds: state.totalSeconds,
            label: 'Speaking Recording',
            isSpeaking: true,
          ),
          const SizedBox(height: 16),

          // Live audio wave visualizer
          AudioWaveVisualizer(
            waveHeights: state.waveHeights,
            isRecording: state.isRecording,
          ),
          const SizedBox(height: 14),

          // Active Recording indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: state.isMicActive ? AppColors.band5 : AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                state.isMicActive
                    ? 'LIVE MICROPHONE ACTIVE • KEEP SPEAKING'
                    : 'PRACTICE TIMER MODE • SPEAK OUT LOUD',
                style: AppTextStyles.label.copyWith(
                  color: state.isMicActive ? AppColors.band5 : AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cue Card reminder
          CueCardBox(cueCard: state.cueCard),

          const SizedBox(height: 24),

          // Stop & Evaluate Button (Solid Royal Blue - NO GRADIENT)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.stop_circle_outlined, color: Colors.white),
              label: const Text('Finish Speaking & Analyze Band Score'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                final spokenSeconds = 120 - state.remainingSeconds;
                context.read<MockTestBloc>().add(
                      StopSpeakingAndAnalyzeEvent(
                        durationSpokenSeconds: spokenSeconds > 10 ? spokenSeconds : 15,
                      ),
                    );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAnalyzingView(MockTestAnalyzingState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Evaluating Speech Performance',
              style: AppTextStyles.h2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              state.statusMessage,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView(BuildContext context, MockTestResultState state) {
    final eval = state.evaluation;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall Band Score Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primaryCard,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eval.isAiEvaluated
                      ? 'OFFICIAL AI EXAMINER EVALUATION'
                      : 'ESTIMATED BAND SCORE (PRACTICE MODE)',
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: 1.0,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Band ${eval.overallBand.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 34,
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  eval.isAiEvaluated
                      ? (eval.id.startsWith('groq_')
                          ? 'Groq Engine (Whisper V3 + LLaMA 3.3)'
                          : 'Google Gemini Multimodal AI')
                      : 'Good Stamina • Fluency Score Estimated',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // User Recorded Speech Player
          if (state.recordedAudioPath != null && state.recordedAudioPath!.isNotEmpty) ...[
            RecordedAudioPlayerWidget(
              audioPath: state.recordedAudioPath!,
              title: 'Listen to Your Speech',
            ),
            const SizedBox(height: 20),
          ],

          // AI Transcription if available
          if (eval.transcription != null && eval.transcription!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SPEECH TRANSCRIPT', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
                  const SizedBox(height: 8),
                  Text(
                    eval.transcription!,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 4 IELTS Criteria Breakdown
          Text('Criteria Breakdown', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          CriteriaScoreCard(
            title: 'Fluency & Coherence',
            code: 'FC',
            score: eval.fluencyBand,
            description: 'Smooth continuity of speech, natural pauses and spontaneous discourse markers.',
          ),
          const SizedBox(height: 10),
          CriteriaScoreCard(
            title: 'Lexical Resource',
            code: 'LR',
            score: eval.lexicalBand,
            description: 'Varied and precise vocabulary, natural idiomatic expressions and accurate collocations.',
          ),
          const SizedBox(height: 10),
          CriteriaScoreCard(
            title: 'Grammar Range & Accuracy',
            code: 'GRA',
            score: eval.grammarBand,
            description: 'Complex sentence structures, conditional clauses, and accurate tense consistency.',
          ),
          const SizedBox(height: 10),
          CriteriaScoreCard(
            title: 'Pronunciation',
            code: 'PR',
            score: eval.pronunciationBand,
            description: 'Clear intonation patterns, word stress, rhythm, and easy intelligibility throughout.',
          ),

          const SizedBox(height: 24),

          // Strengths & Improvements (Solid White card)
          Text('Feedback & Key Insights', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STRENGTHS OBSERVED', style: AppTextStyles.label.copyWith(color: AppColors.secondary, fontSize: 10.5)),
                const SizedBox(height: 8),
                ...eval.strengths.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $s', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                    )),
                const Divider(height: 20),
                Text('AREAS TO IMPROVE', style: AppTextStyles.label.copyWith(color: AppColors.primary, fontSize: 10.5)),
                const SizedBox(height: 8),
                ...eval.areasToImprove.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $a', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Band 9 Model Answer Comparison
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceBorderLight, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Band 9.0 Model Answer', style: AppTextStyles.titleLarge),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.tealSoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Official Standard',
                        style: const TextStyle(
                          color: AppColors.teal,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  state.cueCard.band9ModelAnswer,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Text('High-Scoring Collocations Used:', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: state.cueCard.keyCollocations.map((colloc) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        colloc,
                        style: const TextStyle(
                          color: AppColors.primary,
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

          const SizedBox(height: 28),

          // Continue to Part 3 Discussion
          if (state.cueCard.part3FollowUps.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  context.read<MockTestBloc>().add(const ResetSessionEvent());
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Part3DiscussionPage(cueCard: state.cueCard),
                    ),
                  );
                },
                child: const Text('Continue to Part 3 Discussion'),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Return Home or Repeat (Solid buttons - NO GRADIENTS)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    context.read<MockTestBloc>().add(StartCueCardSessionEvent(state.cueCard));
                  },
                  child: const Text('Try Again'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    context.read<MockTestBloc>().add(const ResetSessionEvent());
                    Navigator.pop(context);
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
