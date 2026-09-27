import 'dart:async';
import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/audio_recording_service.dart';
import '../../domain/entities/cue_card_entity.dart';
import '../../domain/entities/mock_evaluation_entity.dart';
import '../../domain/repositories/speaking_repository.dart';

// EVENTS
abstract class MockTestEvent extends Equatable {
  const MockTestEvent();
  @override
  List<Object?> get props => [];
}

class StartCueCardSessionEvent extends MockTestEvent {
  final CueCardEntity cueCard;
  const StartCueCardSessionEvent(this.cueCard);
  @override
  List<Object?> get props => [cueCard];
}

class SkipPrepToSpeakingEvent extends MockTestEvent {
  const SkipPrepToSpeakingEvent();
}

class TimerTickEvent extends MockTestEvent {
  final int remainingSeconds;
  const TimerTickEvent(this.remainingSeconds);
  @override
  List<Object?> get props => [remainingSeconds];
}

class StopSpeakingAndAnalyzeEvent extends MockTestEvent {
  final int durationSpokenSeconds;
  const StopSpeakingAndAnalyzeEvent({required this.durationSpokenSeconds});
  @override
  List<Object?> get props => [durationSpokenSeconds];
}

class ResetSessionEvent extends MockTestEvent {
  const ResetSessionEvent();
}

// STATES
abstract class MockTestState extends Equatable {
  const MockTestState();
  @override
  List<Object?> get props => [];
}

class MockTestInitialState extends MockTestState {}

class CueCardPreparingState extends MockTestState {
  final CueCardEntity cueCard;
  final int remainingSeconds;
  final int totalSeconds;

  const CueCardPreparingState({
    required this.cueCard,
    required this.remainingSeconds,
    this.totalSeconds = 60,
  });

  @override
  List<Object?> get props => [cueCard, remainingSeconds, totalSeconds];
}

typedef MockTestPreparingState = CueCardPreparingState;

class CueCardSpeakingState extends MockTestState {
  final CueCardEntity cueCard;
  final int remainingSeconds;
  final int totalSeconds;
  final bool isRecording;
  final bool isMicActive;
  final List<double> waveHeights;

  const CueCardSpeakingState({
    required this.cueCard,
    required this.remainingSeconds,
    this.totalSeconds = 120,
    this.isRecording = true,
    this.isMicActive = false,
    required this.waveHeights,
  });

  @override
  List<Object?> get props => [cueCard, remainingSeconds, totalSeconds, isRecording, isMicActive, waveHeights];
}

class MockTestAnalyzingState extends MockTestState {
  final String statusMessage;
  const MockTestAnalyzingState([this.statusMessage = 'Analyzing your speaking duration and generating an estimated band score...']);

  @override
  List<Object?> get props => [statusMessage];
}

class MockTestResultState extends MockTestState {
  final CueCardEntity cueCard;
  final MockEvaluationEntity evaluation;

  const MockTestResultState({
    required this.cueCard,
    required this.evaluation,
  });

  @override
  List<Object?> get props => [cueCard, evaluation];
}

// BLOC
class MockTestBloc extends Bloc<MockTestEvent, MockTestState> {
  final SpeakingRepository repository;
  final AudioRecordingService audioService;

  Timer? _timer;
  CueCardEntity? _currentCueCard;
  int _secondsRemaining = 0;
  bool _isSpeakingPhase = false;
  final Random _random = Random();

  MockTestBloc({required this.repository, AudioRecordingService? audioService})
      : audioService = audioService ?? AudioRecordingService(),
        super(MockTestInitialState()) {
    on<StartCueCardSessionEvent>(_onStartCueCardSession);
    on<SkipPrepToSpeakingEvent>(_onSkipPrepToSpeaking);
    on<TimerTickEvent>(_onTimerTick);
    on<StopSpeakingAndAnalyzeEvent>(_onStopSpeakingAndAnalyze);
    on<ResetSessionEvent>(_onResetSession);
  }

  void _onStartCueCardSession(
    StartCueCardSessionEvent event,
    Emitter<MockTestState> emit,
  ) {
    _timer?.cancel();
    _currentCueCard = event.cueCard;
    _secondsRemaining = 60; // 1 minute preparation
    _isSpeakingPhase = false;

    emit(CueCardPreparingState(
      cueCard: event.cueCard,
      remainingSeconds: _secondsRemaining,
      totalSeconds: 60,
    ));

    _startTimer();
  }

  Future<void> _onSkipPrepToSpeaking(
    SkipPrepToSpeakingEvent event,
    Emitter<MockTestState> emit,
  ) async {
    // Null safety: ensure _currentCueCard is set
    if (_currentCueCard == null) {
      emit(MockTestInitialState());
      return;
    }

    _timer?.cancel();
    _isSpeakingPhase = true;
    _secondsRemaining = 120; // 2 minutes speaking

    // Try to start real audio recording
    bool micActive = false;
    try {
      micActive = await audioService.startRecording();
    } catch (_) {
      micActive = false;
    }

    emit(CueCardSpeakingState(
      cueCard: _currentCueCard!,
      remainingSeconds: _secondsRemaining,
      totalSeconds: 120,
      isMicActive: micActive,
      waveHeights: _generateWaveHeights(micActive),
    ));

    _startTimer();
  }

  Future<void> _onTimerTick(
    TimerTickEvent event,
    Emitter<MockTestState> emit,
  ) async {
    if (_currentCueCard == null) {
      emit(MockTestInitialState());
      return;
    }

    if (!_isSpeakingPhase) {
      if (event.remainingSeconds <= 0) {
        // Auto transition from prep to speaking
        add(const SkipPrepToSpeakingEvent());
      } else {
        emit(CueCardPreparingState(
          cueCard: _currentCueCard!,
          remainingSeconds: event.remainingSeconds,
          totalSeconds: 60,
        ));
      }
    } else {
      if (event.remainingSeconds <= 0) {
        add(const StopSpeakingAndAnalyzeEvent(durationSpokenSeconds: 120));
      } else {
        // Try to get real amplitude for wave visualization
        List<double> waveHeights = _generateWaveHeights(false);
        bool micActive = false;
        try {
          if (audioService.isRecording) {
            micActive = true;
            final amp = await audioService.getAmplitude();
            final normalized = (amp.current + 60).clamp(0, 60) / 60.0;
            waveHeights = List.generate(24, (_) {
              return (0.15 + normalized * 0.85 + (_random.nextDouble() * 0.2))
                  .clamp(0.12, 1.0);
            });
          }
        } catch (_) {}

        emit(CueCardSpeakingState(
          cueCard: _currentCueCard!,
          remainingSeconds: event.remainingSeconds,
          totalSeconds: 120,
          isMicActive: micActive,
          waveHeights: waveHeights,
        ));
      }
    }
  }

  Future<void> _onStopSpeakingAndAnalyze(
    StopSpeakingAndAnalyzeEvent event,
    Emitter<MockTestState> emit,
  ) async {
    _timer?.cancel();

    // Stop audio recording if active
    try {
      if (audioService.isRecording) {
        await audioService.stopRecording();
      }
    } catch (_) {}

    emit(const MockTestAnalyzingState(
      'Analyzing your speaking duration and generating an estimated band score...'
    ));

    // Realistic delay for evaluation computation
    await Future.delayed(const Duration(milliseconds: 1400));

    final result = await repository.submitMockTestEvaluation(
      testTitle: _currentCueCard?.title ?? 'IELTS Cue Card',
      durationSeconds: event.durationSpokenSeconds,
    );

    result.fold(
      (failure) => emit(MockTestInitialState()),
      (evaluation) {
        emit(MockTestResultState(
          cueCard: _currentCueCard!,
          evaluation: evaluation,
        ));
      },
    );
  }

  void _onResetSession(
    ResetSessionEvent event,
    Emitter<MockTestState> emit,
  ) {
    _timer?.cancel();
    // Clean up any active recording without permanently destroying the singleton recorder
    audioService.reset();
    _currentCueCard = null;
    _isSpeakingPhase = false;
    emit(MockTestInitialState());
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsRemaining--;
      add(TimerTickEvent(_secondsRemaining));
    });
  }

  /// Generates wave heights for visualization.
  /// If mic is active, real amplitude is used by the caller.
  /// Otherwise, generates a gentle simulated wave.
  List<double> _generateWaveHeights(bool micActive) {
    if (micActive) {
      // Real amplitude will replace this in _onTimerTick
      return List.generate(24, (_) => 0.15 + (_random.nextDouble() * 0.85));
    }
    // Simulated gentle wave when no mic
    return List.generate(24, (_) {
      return (0.2 + (_random.nextDouble() * 0.5)).clamp(0.12, 0.8);
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    audioService.reset();
    return super.close();
  }
}

