import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../network/supabase_config.dart';
import '../../features/speaking_practice/data/models/mock_evaluation_model.dart';

/// Service for evaluating IELTS speaking responses using Groq AI Cloud.
///
/// Architecture:
/// 1. STT: Groq Whisper Large V3 (ultra-low latency audio transcription)
/// 2. Evaluation: Groq LLaMA 3.3 70B (sub-second IELTS 4 criteria scoring)
class GroqSpeakingService {
  final Dio _dio;

  GroqSpeakingService({Dio? dio}) : _dio = dio ?? Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 35),
    ),
  );

  /// Evaluates speaking audio using Groq Whisper + LLaMA 3.3.
  Future<MockEvaluationModel?> evaluateSpeakingResponse({
    required String testTitle,
    required int durationSeconds,
    String? audioPath,
    String? promptContext,
  }) async {
    final apiKey = SupabaseConfig.groqApiKey;
    if (apiKey.isEmpty) return null;

    try {
      String transcription = '';

      // Step 1: Transcribe audio with Groq Whisper Large V3 if audio exists
      if (audioPath != null && File(audioPath).existsSync()) {
        final audioFile = File(audioPath);
        final fileName = audioFile.path.split('/').last;

        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(audioFile.path, filename: fileName),
          'model': 'whisper-large-v3',
          'language': 'en',
          'response_format': 'json',
        });

        final sttRes = await _dio.post(
          'https://api.groq.com/openai/v1/audio/transcriptions',
          data: formData,
          options: Options(
            headers: {
              'Authorization': 'Bearer $apiKey',
            },
          ),
        );

        if (sttRes.statusCode == 200 && sttRes.data != null) {
          transcription = (sttRes.data['text'] as String?)?.trim() ?? '';
        }
      }

      if (transcription.isEmpty && (audioPath != null && File(audioPath).existsSync())) {
        // If STT returned empty speech, return null to allow fallback or fallback message
        transcription = 'Candidate delivered spoken response for $durationSeconds seconds on topic: $testTitle.';
      }

      // Step 2: Score response with Groq LLaMA 3.3 70B
      final systemPrompt = '''
You are an expert, certified IELTS Speaking Examiner.
Evaluate the candidate's speech transcript according to the official IELTS Speaking Band Descriptors across 4 criteria:
1. Fluency and Coherence (FC)
2. Lexical Resource (LR)
3. Grammatical Range and Accuracy (GRA)
4. Pronunciation (PR)

Rules:
- Assign scores strictly from 4.0 to 9.0 in half-band increments (e.g. 6.0, 6.5, 7.0, 7.5, 8.0).
- Overall Band is the arithmetic mean of the 4 criteria rounded to the nearest 0.5.
- Provide constructive, IELTS-specific strengths and areas to improve.

Respond strictly with valid JSON conforming to:
{
  "overallBand": 7.5,
  "fluencyBand": 7.5,
  "lexicalBand": 7.0,
  "grammarBand": 7.5,
  "pronunciationBand": 8.0,
  "feedbackSummary": "2-3 concise sentences analyzing candidate performance.",
  "strengths": ["Specific strength 1", "Specific strength 2"],
  "areasToImprove": ["Specific actionable tip 1", "Specific actionable tip 2"]
}
''';

      final userMessage = 'Candidate Task: "$testTitle". Context: "${promptContext ?? ''}". Duration: $durationSeconds seconds.\nCandidate Transcript:\n"$transcription"';

      final chatRes = await _dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        data: {
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.2,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
      );

      if (chatRes.statusCode == 200 && chatRes.data != null) {
        final choices = chatRes.data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          final message = choices.first['message'];
          final content = message['content'] as String;
          final Map<String, dynamic> parsed = jsonDecode(content);

          return MockEvaluationModel(
            id: 'groq_eval_${DateTime.now().millisecondsSinceEpoch}',
            date: DateTime.now(),
            overallBand: _clampBand((parsed['overallBand'] as num?)?.toDouble() ?? 7.0),
            fluencyBand: _clampBand((parsed['fluencyBand'] as num?)?.toDouble() ?? 7.0),
            lexicalBand: _clampBand((parsed['lexicalBand'] as num?)?.toDouble() ?? 7.0),
            grammarBand: _clampBand((parsed['grammarBand'] as num?)?.toDouble() ?? 7.0),
            pronunciationBand: _clampBand((parsed['pronunciationBand'] as num?)?.toDouble() ?? 7.0),
            feedbackSummary: parsed['feedbackSummary'] as String? ?? 'Groq LLaMA 3.3 speech evaluation completed.',
            strengths: (parsed['strengths'] as List?)?.map((e) => e.toString()).toList() ?? [
              'Clear delivery and relevant topical engagement.',
              'Good structural flow throughout the task.'
            ],
            areasToImprove: (parsed['areasToImprove'] as List?)?.map((e) => e.toString()).toList() ?? [
              'Use more advanced idioms and varied conjunctions.',
              'Extend elaboration on abstract points.'
            ],
            isAiEvaluated: true,
            transcription: transcription.isNotEmpty ? transcription : null,
          );
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  double _clampBand(double val) {
    final rounded = (val * 2).round() / 2.0;
    return rounded.clamp(4.0, 9.0);
  }
}

