import 'package:flutter_test/flutter_test.dart';
import 'package:ielts_speaky/core/services/ai_speaking_service.dart';
import 'package:ielts_speaky/core/services/gemini_speaking_service.dart';
import 'package:ielts_speaky/core/services/groq_speaking_service.dart';
import 'package:ielts_speaky/features/speaking_practice/data/models/mock_evaluation_model.dart';

void main() {
  group('AiSpeakingService Dual-Engine Orchestration Tests', () {
    late AiSpeakingService aiService;

    setUp(() {
      aiService = AiSpeakingService();
    });

    test('AiSpeakingService gracefully falls back to Practice Mode when no keys provided', () async {
      final result = await aiService.evaluateSpeakingResponse(
        testTitle: 'Describe a memorable journey',
        durationSeconds: 110,
      );

      expect(result.overallBand, equals(7.5));
      expect(result.fluencyBand, equals(7.5));
      expect(result.strengths, isNotEmpty);
      expect(result.areasToImprove, isNotEmpty);
    });

    test('Short response (< 30s) receives lower band score in practice mode', () async {
      final result = await aiService.evaluateSpeakingResponse(
        testTitle: 'Describe your hometown',
        durationSeconds: 15,
      );

      expect(result.overallBand, equals(6.0));
      expect(result.fluencyBand, equals(5.5));
    });
  });

  group('GeminiSpeakingService Unit Tests', () {
    late GeminiSpeakingService service;

    setUp(() {
      service = GeminiSpeakingService();
    });

    test('Offline evaluation returns Band 7.5 for speech >= 95 seconds', () async {
      final result = await service.evaluateSpeakingResponse(
        testTitle: 'Test Cue Card',
        durationSeconds: 100,
      );

      expect(result.overallBand, equals(7.5));
      expect(result.fluencyBand, equals(7.5));
      expect(result.isAiEvaluated, isFalse);
    });
  });

  group('MockEvaluationModel Serialization Tests', () {
    test('MockEvaluationModel converts to and from JSON accurately', () {
      final now = DateTime.now();
      final model = MockEvaluationModel(
        id: 'groq_eval_test',
        date: now,
        overallBand: 8.0,
        fluencyBand: 8.0,
        lexicalBand: 7.5,
        grammarBand: 8.0,
        pronunciationBand: 8.5,
        feedbackSummary: 'Excellent coherence and rich collocations from Groq engine.',
        strengths: ['Natural pacing', 'Accurate idioms'],
        areasToImprove: ['Use more inverted conditionals'],
        isAiEvaluated: true,
        transcription: 'I would like to talk about...',
      );

      final json = model.toJson();
      expect(json['id'], equals('groq_eval_test'));
      expect(json['overallBand'], equals(8.0));
      expect(json['isAiEvaluated'], isTrue);
      expect(json['transcription'], equals('I would like to talk about...'));

      final fromJson = MockEvaluationModel.fromJson(json);
      expect(fromJson.id, equals(model.id));
      expect(fromJson.overallBand, equals(model.overallBand));
      expect(fromJson.isAiEvaluated, isTrue);
      expect(fromJson.transcription, equals(model.transcription));
    });
  });
}
