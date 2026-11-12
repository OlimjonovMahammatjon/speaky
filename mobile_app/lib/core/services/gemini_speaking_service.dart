import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../network/supabase_config.dart';
import '../../features/speaking_practice/data/models/mock_evaluation_model.dart';

/// Service for evaluating IELTS speaking responses using Google Gemini AI.
///
/// Features:
/// - Direct multimodal audio understanding (sends recorded m4a/aac to Gemini 1.5/2.0 Flash)
/// - Authentic IELTS 4-criteria scoring: FC, LR, GRA, PR (0.0 to 9.0 in 0.5 steps)
/// - Speech transcription and actionable examiner feedback
/// - Seamless fallback to offline heuristic scoring if offline or API key omitted
class GeminiSpeakingService {
  static const String systemInstruction = '''
You are an expert, certified IELTS Speaking Examiner.
Listen carefully to the candidate's audio response (or read the context if audio is omitted) and evaluate it according to the official IELTS Speaking Band Descriptors across 4 criteria:
1. Fluency and Coherence (FC)
2. Lexical Resource (LR)
3. Grammatical Range and Accuracy (GRA)
4. Pronunciation (PR)

Rules:
- Assign scores strictly from 4.0 to 9.0 in half-band increments (e.g. 6.0, 6.5, 7.0, 7.5, 8.0).
- Overall Band is the arithmetic mean of the 4 criteria rounded to the nearest 0.5.
- Transcribe the candidate's speech accurately in "transcription" (or empty string if no audio).
- Provide constructive, IELTS-specific strengths and areas to improve.

Respond strictly with valid JSON conforming to:
{
  "overallBand": 7.5,
  "fluencyBand": 7.5,
  "lexicalBand": 7.0,
  "grammarBand": 7.5,
  "pronunciationBand": 8.0,
  "transcription": "Accurate word-for-word speech transcript.",
  "feedbackSummary": "2-3 concise sentences analyzing candidate performance.",
  "strengths": ["Specific strength 1", "Specific strength 2"],
  "areasToImprove": ["Specific actionable tip 1", "Specific actionable tip 2"]
}
''';

  final Dio _dio;

  GeminiSpeakingService({Dio? dio}) : _dio = dio ?? Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 25),
      receiveTimeout: const Duration(seconds: 40),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  /// Evaluates an IELTS speaking session with either audio file or text prompt.
  Future<MockEvaluationModel> evaluateSpeakingResponse({
    required String testTitle,
    required int durationSeconds,
    String? audioPath,
    String? promptContext,
  }) async {
    final apiKey = SupabaseConfig.geminiApiKey;

    // If no API key configured or audio file doesn't exist, use offline heuristic
    if (apiKey.isEmpty || (audioPath != null && !File(audioPath).existsSync())) {
      return _generateOfflineEvaluation(testTitle, durationSeconds);
    }

    try {
      // Prepare request parts (with audio if provided and exists, otherwise text-only)
      final requestParts = <Map<String, dynamic>>[
        {
          'text': 'Topic/Task: $testTitle. ${promptContext != null ? 'Context: $promptContext.' : ''} Candidate spoke for $durationSeconds seconds. Please evaluate this speaking response according to official IELTS criteria:'
        }
      ];

      if (audioPath != null && File(audioPath).existsSync()) {
        final file = File(audioPath);
        final bytes = await file.readAsBytes();
        final base64Audio = base64Encode(bytes);
        final isM4a = audioPath.endsWith('.m4a');
        final mimeType = isM4a ? 'audio/mp4' : 'audio/aac';

        requestParts.add({
          'inlineData': {
            'mimeType': mimeType,
            'data': base64Audio,
          }
        });
      }

      final requestData = {
        'contents': [
          {
            'role': 'user',
            'parts': requestParts,
          }
        ],
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction}
          ]
        },
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.2,
        }
      };

      // Call Gemini 1.5 Flash (fast & native audio support)
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey';
      final response = await _dio.post(url, data: requestData);

      if (response.statusCode == 200 && response.data != null) {
        final candidates = response.data['candidates'] as List?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates.first['content'];
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final rawJsonText = (parts.first['text'] as String).trim();

            // Robust JSON extraction between outermost { and }
            final startIdx = rawJsonText.indexOf('{');
            final endIdx = rawJsonText.lastIndexOf('}');
            if (startIdx != -1 && endIdx != -1 && endIdx >= startIdx) {
              final jsonSubstring = rawJsonText.substring(startIdx, endIdx + 1);
              final Map<String, dynamic> parsed = jsonDecode(jsonSubstring);

              return MockEvaluationModel(
                id: 'ai_eval_${DateTime.now().millisecondsSinceEpoch}',
                date: DateTime.now(),
                overallBand: _clampBand((parsed['overallBand'] as num?)?.toDouble() ?? 7.0),
                fluencyBand: _clampBand((parsed['fluencyBand'] as num?)?.toDouble() ?? 7.0),
                lexicalBand: _clampBand((parsed['lexicalBand'] as num?)?.toDouble() ?? 7.0),
                grammarBand: _clampBand((parsed['grammarBand'] as num?)?.toDouble() ?? 7.0),
                pronunciationBand: _clampBand((parsed['pronunciationBand'] as num?)?.toDouble() ?? 7.0),
                feedbackSummary: parsed['feedbackSummary'] as String? ?? 'Comprehensive AI evaluation completed.',
                strengths: (parsed['strengths'] as List?)?.map((e) => e.toString()).toList() ?? [
                  'Good task achievement and relevant response.',
                  'Natural intonation on key lexical phrases.'
                ],
                areasToImprove: (parsed['areasToImprove'] as List?)?.map((e) => e.toString()).toList() ?? [
                  'Incorporate more diverse complex conditional structures.',
                  'Extend answers with personal anecdotes.'
                ],
                isAiEvaluated: true,
                transcription: parsed['transcription'] as String?,
              );
            }
          }
        }
      }

      // If response was not 200 or parsing failed, fallback gracefully
      return _generateOfflineEvaluation(testTitle, durationSeconds);
    } catch (_) {
      // Offline fallback on network timeout or quota limit
      return _generateOfflineEvaluation(testTitle, durationSeconds);
    }
  }

  /// Clamps a band score to official IELTS 0.5 increments between 4.0 and 9.0.
  double _clampBand(double val) {
    final rounded = (val * 2).round() / 2.0;
    return rounded.clamp(4.0, 9.0);
  }

  /// High quality offline evaluation fallback based on speaking duration.
  MockEvaluationModel _generateOfflineEvaluation(String testTitle, int durationSeconds) {
    double fluency;
    double lexical;
    double grammar;
    double pronunciation;

    if (durationSeconds >= 95) {
      fluency = 7.5;
      lexical = 7.5;
      grammar = 7.0;
      pronunciation = 7.5;
    } else if (durationSeconds >= 60) {
      fluency = 7.0;
      lexical = 7.0;
      grammar = 6.5;
      pronunciation = 7.0;
    } else if (durationSeconds >= 30) {
      fluency = 6.0;
      lexical = 6.5;
      grammar = 6.0;
      pronunciation = 6.5;
    } else {
      fluency = 5.5;
      lexical = 6.0;
      grammar = 5.5;
      pronunciation = 6.0;
    }

    final rawOverall = (fluency + lexical + grammar + pronunciation) / 4.0;
    final overall = (rawOverall * 2).round() / 2.0;

    final strengths = <String>[
      if (durationSeconds >= 90)
        'You sustained speech for $durationSeconds seconds — exceptional stamina and continuous flow.'
      else if (durationSeconds >= 60)
        'Solid flow maintained for $durationSeconds seconds. Good effort on staying on topic.'
      else
        'Session completed ($durationSeconds seconds). You tackled the prompt directly.',
      'Appropriate use of natural discourse markers and cohesive linkers.',
      'Clear sentence pacing with audible emphasis on key words.',
    ];

    final areasToImprove = <String>[
      if (durationSeconds < 90)
        'Aim to speak for the full 2 minutes — extend your response with a vivid story or example.',
      'Incorporate more inverted conditionals (e.g. "Were I to...", "Had I known...") for grammar diversity.',
      'Practice paraphrasing prompts rather than repeating introductory examiner phrases.',
    ];

    return MockEvaluationModel(
      id: 'eval_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      overallBand: overall,
      fluencyBand: fluency,
      lexicalBand: lexical,
      grammarBand: grammar,
      pronunciationBand: pronunciation,
      feedbackSummary: 'Practice Mode: This evaluation was generated based on your speaking '
          'flow and duration ($durationSeconds seconds). To enable Deep AI speech evaluation with '
          'automatic transcription, add your Gemini API Key in .env.',
      strengths: strengths,
      areasToImprove: areasToImprove,
      isAiEvaluated: false,
    );
  }
}

