import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/services/audio_recording_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../injection_container.dart';
import '../../domain/entities/cue_card_entity.dart';
import '../../domain/entities/question_entity.dart';
import '../../domain/entities/topic_entity.dart';
import '../../domain/entities/mock_evaluation_entity.dart';
import '../../domain/repositories/speaking_repository.dart';
import '../bloc/speaking_bloc.dart';
import '../widgets/audio_wave_visualizer.dart';
import '../widgets/countdown_timer_widget.dart';
import '../widgets/cue_card_box.dart';
import '../widgets/criteria_score_card.dart';
import '../widgets/recorded_audio_player_widget.dart';
import '../widgets/question_audio_recorder_widget.dart';

enum FullMockPhase {
  intro,
  part1,
  part2Prep,
  part2Speaking,
  part3,
  evaluating,
  results,
}

class FullMockSimulationPage extends StatefulWidget {
  final CueCardEntity cueCard;
  final List<QuestionEntity> part1Questions;

  const FullMockSimulationPage({
    super.key,
    required this.cueCard,
    required this.part1Questions,
  });

  @override
  State<FullMockSimulationPage> createState() => _FullMockSimulationPageState();
}

class _FullMockSimulationPageState extends State<FullMockSimulationPage> {
  final AudioRecordingService _audioService = sl<AudioRecordingService>();
  final SpeakingRepository _repository = sl<SpeakingRepository>();

  FullMockPhase _currentPhase = FullMockPhase.intro;
  int _part1CurrentIndex = 0;
  int _part3CurrentIndex = 0;
  int _secondsRemaining = 0;
  Timer? _timer;

  // Audio recording modes
  bool _continuousRecordingEnabled = true;
  AudioRecorder? _continuousRecorder;
  String? _fullExamContinuousAudioPath;
  final Map<String, String> _perQuestionAudioMap = {};

  bool _isMicRecording = false;
  String? _recordedAudioPath;
  int _totalSpokenSeconds = 0;
  MockEvaluationEntity? _finalEvaluation;

  @override
  void initState() {
    super.initState();
    _continuousRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _continuousRecorder?.dispose();
    _audioService.reset();
    super.dispose();
  }
    _timer?.cancel();
    _audioService.reset();
    super.dispose();
  }

  void _startPart1() {
    setState(() {
      _currentPhase = FullMockPhase.part1;
      _part1CurrentIndex = 0;
    });
  }

  void _nextPart1Question() {
    if (_part1CurrentIndex + 1 < widget.part1Questions.length) {
      setState(() {
        _part1CurrentIndex++;
      });
    } else {
      // Transition to Part 2 Prep
      _startPart2Prep();
    }
  }

  void _startPart2Prep() {
    _timer?.cancel();
    setState(() {
      _currentPhase = FullMockPhase.part2Prep;
      _secondsRemaining = 60; // 1 min prep
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _startPart2Speaking();
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _startPart2Speaking() async {
    _timer?.cancel();
    bool micActive = false;
    try {
      micActive = await _audioService.startRecording();
    } catch (_) {}

    setState(() {
      _currentPhase = FullMockPhase.part2Speaking;
      _secondsRemaining = 120; // 2 min speech
      _isMicRecording = micActive;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _finishPart2Speaking();
      } else {
        setState(() {
          _secondsRemaining--;
          _totalSpokenSeconds++;
        });
      }
    });
  }

  Future<void> _finishPart2Speaking() async {
    _timer?.cancel();
    try {
      if (_audioService.isRecording) {
        _recordedAudioPath = await _audioService.stopRecording();
      }
    } catch (_) {}

    setState(() {
      _isMicRecording = false;
      _currentPhase = FullMockPhase.part3;
      _part3CurrentIndex = 0;
    });
  }

  void _nextPart3Question() {
    final followUps = widget.cueCard.part3FollowUps;
    if (_part3CurrentIndex + 1 < followUps.length) {
      setState(() {
        _part3CurrentIndex++;
      });
    } else {
      _evaluateAndShowResults();
    }
  }

  Future<void> _evaluateAndShowResults() async {
    setState(() {
      _currentPhase = FullMockPhase.evaluating;
    });

    final totalSeconds = _totalSpokenSeconds > 0 ? _totalSpokenSeconds : 90;
    final result = await _repository.submitMockTestEvaluation(
      testTitle: 'Full Mock: ${widget.cueCard.title}',
      durationSeconds: totalSeconds,
      audioPath: _recordedAudioPath,
      promptContext: widget.cueCard.cuePrompt,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _currentPhase = FullMockPhase.intro;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Evaluation error: ${failure.message}')),
        );
      },
      (evaluation) {
        setState(() {
          _finalEvaluation = evaluation;
          _currentPhase = FullMockPhase.results;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getAppBarTitle(), style: AppTextStyles.h3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 24),
          onPressed: () {
            if (_currentPhase != FullMockPhase.intro && _currentPhase != FullMockPhase.results) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Quit Simulation?'),
                  content: const Text('Are you sure you want to quit the IELTS Speaking Simulation? Your current progress will not be saved.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Stay')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('Quit Exam', style: TextStyle(color: AppColors.rose)),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: _buildPhaseContent(),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentPhase) {
      case FullMockPhase.intro:
        return 'Exam Overview';
      case FullMockPhase.part1:
        return 'Part 1: Introduction';
      case FullMockPhase.part2Prep:
        return 'Part 2: Preparation';
      case FullMockPhase.part2Speaking:
        return 'Part 2: Candidate Speech';
      case FullMockPhase.part3:
        return 'Part 3: Discussion';
      case FullMockPhase.evaluating:
        return 'AI Examiner Evaluation';
      case FullMockPhase.results:
        return 'Official Exam Report';
    }
  }

  Widget _buildPhaseContent() {
    switch (_currentPhase) {
      case FullMockPhase.intro:
        return _buildIntroView();
      case FullMockPhase.part1:
        return _buildPart1View();
      case FullMockPhase.part2Prep:
        return _buildPart2PrepView();
      case FullMockPhase.part2Speaking:
        return _buildPart2SpeakingView();
      case FullMockPhase.part3:
        return _buildPart3View();
      case FullMockPhase.evaluating:
        return _buildEvaluatingView();
      case FullMockPhase.results:
        return _buildResultsView();
    }
  }

  Widget _buildIntroView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                Text(
                  'OFFICIAL IELTS EXAM SIMULATION',
                  style: AppTextStyles.label.copyWith(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete 3-Part Assessment',
                  style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  'You will undergo all 3 parts of the official test. The AI Examiner will evaluate your recording across Fluency, Lexical Resource, Grammar, and Pronunciation.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Your Exam Package Today:', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          _buildSummaryTile('Part 1', '${widget.part1Questions.length} Interview questions on everyday topics', Icons.chat_bubble_outline, AppColors.teal),
          const SizedBox(height: 10),
          _buildSummaryTile('Part 2', widget.cueCard.title, Icons.timer_outlined, AppColors.primary),
          const SizedBox(height: 10),
          _buildSummaryTile('Part 3', '${widget.cueCard.part3FollowUps.length} In-depth societal discussion questions', Icons.forum_outlined, AppColors.orange),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
              label: const Text('Begin Official Simulation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _startPart1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile(String badge, String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorderLight, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge, style: AppTextStyles.label.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(title, style: AppTextStyles.titleMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPart1View() {
    final q = widget.part1Questions[_part1CurrentIndex];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('QUESTION ${_part1CurrentIndex + 1} OF ${widget.part1Questions.length}', style: AppTextStyles.overline),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.tealSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Part 1 • 4-5 Mins', style: const TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorderLight, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.record_voice_over_rounded, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        q.question_text,
                        style: AppTextStyles.h2.copyWith(fontSize: 19),
                      ),
                    ),
                  ],
                ),
                if (q.ideas.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text('💡 Examiner Tip / Key Angle:', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text(q.ideas.first, style: AppTextStyles.bodyMedium),
                ],
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              label: Text(_part1CurrentIndex + 1 < widget.part1Questions.length ? 'Next Question' : 'Proceed to Part 2 (Cue Card)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _nextPart1Question,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPart2PrepView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CountdownTimerWidget(
            remainingSeconds: _secondsRemaining,
            totalSeconds: 60,
            label: 'Preparation Time Remaining',
            progressColor: AppColors.teal,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: CueCardBox(cueCard: widget.cueCard),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _startPart2Speaking,
              child: const Text('I am Ready to Speak (Skip Timer)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPart2SpeakingView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CountdownTimerWidget(
            remainingSeconds: _secondsRemaining,
            totalSeconds: 120,
            label: 'Speaking Delivery Time',
            progressColor: AppColors.orange,
          ),
          const SizedBox(height: 20),
          AudioWaveVisualizer(
            isRecording: true,
            waveHeights: List.generate(24, (i) => (0.2 + (i % 5) * 0.15)),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: CueCardBox(cueCard: widget.cueCard),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _finishPart2Speaking,
              child: const Text('Complete Speech & Proceed to Part 3'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPart3View() {
    final followUps = widget.cueCard.part3FollowUps;
    final currentQ = followUps.isNotEmpty ? followUps[_part3CurrentIndex] : 'Discuss broader societal implications.';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PART 3 DISCUSSION', style: AppTextStyles.overline),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.orangeSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Question ${_part3CurrentIndex + 1} of ${followUps.length}', style: const TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorderLight, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.orangeSoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.forum_outlined, color: AppColors.orange, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        currentQ,
                        style: AppTextStyles.h2.copyWith(fontSize: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 10),
                Text('Examiner Focus:', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Express balanced viewpoints, use speculative conditionals (e.g. "If governments were to..."), and avoid one-word answers.', style: AppTextStyles.bodyMedium),
              ],
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              label: Text(_part3CurrentIndex + 1 < followUps.length ? 'Next Discussion Question' : 'Finish Exam & Receive Official AI Score'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _nextPart3Question,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluatingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3.5),
            const SizedBox(height: 24),
            Text('Evaluating Your Complete Simulation...', style: AppTextStyles.h2, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            Text(
              'The AI Examiner is scoring your response across Fluency, Lexical Resource, Grammar, and Pronunciation.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsView() {
    final eval = _finalEvaluation;
    if (eval == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Overall Band Banner
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primaryCard,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eval.isAiEvaluated ? 'OFFICIAL AI EXAM REPORT' : 'SIMULATION RESULT (PRACTICE MODE)',
                        style: AppTextStyles.label.copyWith(color: Colors.white70, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Band ${eval.overallBand.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eval.isAiEvaluated
                            ? (eval.id.startsWith('groq_')
                                ? '⚡ Certified by Groq LLaMA 3.3 & Whisper V3'
                                : '🧠 Certified by Google Gemini Multimodal AI')
                            : 'Full Exam Completed Successfully',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 38),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Audio Player if recording exists
          if (_recordedAudioPath != null && _recordedAudioPath!.isNotEmpty) ...[
            RecordedAudioPlayerWidget(
              audioPath: _recordedAudioPath!,
              title: 'Listen to Part 2 Speech',
            ),
            const SizedBox(height: 20),
          ],

          // Speech Transcript if AI evaluated
          if (eval.transcription != null && eval.transcription!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorderLight, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.record_voice_over_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text('AI Speech Transcript', style: AppTextStyles.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(eval.transcription!, style: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 4 Criteria breakdown
          Text('Examiner Assessment Breakdown', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          CriteriaScoreCard(title: 'Fluency & Coherence', code: 'FC', score: eval.fluencyBand, description: 'Smooth flow, rhythm, natural linking.'),
          const SizedBox(height: 10),
          CriteriaScoreCard(title: 'Lexical Resource', code: 'LR', score: eval.lexicalBand, description: 'C1/C2 collocations, topic precision.'),
          const SizedBox(height: 10),
          CriteriaScoreCard(title: 'Grammar Range & Accuracy', code: 'GRA', score: eval.grammarBand, description: 'Complex clauses, conditionals, tense accuracy.'),
          const SizedBox(height: 10),
          CriteriaScoreCard(title: 'Pronunciation', code: 'PR', score: eval.pronunciationBand, description: 'Stress timing, intonation, melody.'),
          const SizedBox(height: 24),

          // Strengths & Improvements
          Text('Examiner Feedback', style: AppTextStyles.h3),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceBorderLight, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...eval.strengths.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(s, style: AppTextStyles.bodyMedium)),
                    ],
                  ),
                )),
                const Divider(height: 20),
                ...eval.areasToImprove.map((a) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.arrow_circle_up_rounded, color: AppColors.primary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(a, style: AppTextStyles.bodyMedium)),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Home Dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}

