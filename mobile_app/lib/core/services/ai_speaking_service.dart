import 'dart:async';
import '../network/supabase_config.dart';
import '../../features/speaking_practice/data/models/mock_evaluation_model.dart';
import 'gemini_speaking_service.dart';
import 'groq_speaking_service.dart';

/// Unified Dual-Engine AI Speaking Orchestrator.
///
/// Features:
/// - Parallel Dual-Race ("Whichever returns first wins"): Runs Gemini and Groq simultaneously
/// - Zero-Downtime Auto-Failover: If one engine encounters rate limits or errors, the other seamlessly provides evaluation
/// - Supabase Remote Config: Automatically fetches admin-configured API keys from `app_settings`
/// - Graceful Offline Fallback: High-quality Practice Mode scoring when network is disconnected
class AiSpeakingService {
  final GeminiSpeakingService geminiService;
  final GroqSpeakingService groqService;

  AiSpeakingService({
    GeminiSpeakingService? geminiService,
    GroqSpeakingService? groqService,
  })  : geminiService = geminiService ?? GeminiSpeakingService(),
        groqService = groqService ?? GroqSpeakingService();

  /// Synchronizes dynamic API keys and settings from Supabase `app_settings` table.
  Future<void> syncRemoteSettings() async {
    final client = SupabaseConfig.client;
    if (client == null) return;

    try {
      final response = await client.from('app_settings').select();
      final List data = response as List;

      String? geminiKey;
      String? groqKey;
      String? activeProvider;

      for (final row in data) {
        final key = row['key'] as String?;
        final value = row['value'] as String?;
        if (key == 'gemini_api_key') geminiKey = value;
        if (key == 'groq_api_key') groqKey = value;
        if (key == 'active_ai_provider') activeProvider = value;
      }

      SupabaseConfig.setDynamicConfig(
        geminiKey: geminiKey,
        groqKey: groqKey,
        aiProvider: activeProvider,
      );
    } catch (_) {
      // Ignored if offline or table not seeded yet
    }
  }

  /// Evaluates speaking audio using the best available AI engine.
  ///
  /// In 'auto' mode: Races Gemini and Groq in parallel — the fastest successful
  /// response is returned immediately.
  Future<MockEvaluationModel> evaluateSpeakingResponse({
    required String testTitle,
    required int durationSeconds,
    String? audioPath,
    String? promptContext,
  }) async {
    // 1. Try to sync latest remote settings first if online
    await syncRemoteSettings();

    final mode = SupabaseConfig.activeAiProvider;
    final hasGemini = SupabaseConfig.isGeminiConfigured;
    final hasGroq = SupabaseConfig.isGroqConfigured;

    // Mode A: AUTO (Dual Race: First responding engine wins)
    if (mode == 'auto' || (hasGemini && hasGroq)) {
      final futures = <Future<MockEvaluationModel?>>[];

      if (hasGemini) {
        futures.add(geminiService.evaluateSpeakingResponse(
          testTitle: testTitle,
          durationSeconds: durationSeconds,
          audioPath: audioPath,
          promptContext: promptContext,
        ));
      }

      if (hasGroq) {
        futures.add(groqService.evaluateSpeakingResponse(
          testTitle: testTitle,
          durationSeconds: durationSeconds,
          audioPath: audioPath,
          promptContext: promptContext,
        ));
      }

      if (futures.isNotEmpty) {
        final result = await _firstSuccessful(futures);
        if (result != null) return result;
      }
    }

    // Mode B: Prefer Groq
    if (mode == 'groq' && hasGroq) {
      final groqResult = await groqService.evaluateSpeakingResponse(
        testTitle: testTitle,
        durationSeconds: durationSeconds,
        audioPath: audioPath,
        promptContext: promptContext,
      );
      if (groqResult != null) return groqResult;

      // Fallback to Gemini
      if (hasGemini) {
        return await geminiService.evaluateSpeakingResponse(
          testTitle: testTitle,
          durationSeconds: durationSeconds,
          audioPath: audioPath,
          promptContext: promptContext,
        );
      }
    }

    // Mode C: Prefer Gemini
    if (hasGemini) {
      final geminiResult = await geminiService.evaluateSpeakingResponse(
        testTitle: testTitle,
        durationSeconds: durationSeconds,
        audioPath: audioPath,
        promptContext: promptContext,
      );
      if (geminiResult.isAiEvaluated) return geminiResult;

      // Fallback to Groq
      if (hasGroq) {
        final groqResult = await groqService.evaluateSpeakingResponse(
          testTitle: testTitle,
          durationSeconds: durationSeconds,
          audioPath: audioPath,
          promptContext: promptContext,
        );
        if (groqResult != null) return groqResult;
      }

      return geminiResult;
    }

    // Mode D: Only Groq available
    if (hasGroq) {
      final groqResult = await groqService.evaluateSpeakingResponse(
        testTitle: testTitle,
        durationSeconds: durationSeconds,
        audioPath: audioPath,
        promptContext: promptContext,
      );
      if (groqResult != null) return groqResult;
    }

    // Fallback: Offline heuristic evaluation
    return geminiService.evaluateSpeakingResponse(
      testTitle: testTitle,
      durationSeconds: durationSeconds,
      audioPath: null,
      promptContext: promptContext,
    );
  }

  /// Returns the first Future that completes with a non-null result and isAiEvaluated == true.
  /// If one fails or returns null, waits for the other.
  Future<MockEvaluationModel?> _firstSuccessful(List<Future<MockEvaluationModel?>> futures) async {
    final completer = Completer<MockEvaluationModel?>();
    int pending = futures.length;

    for (final future in futures) {
      future.then((result) {
        if (!completer.isCompleted && result != null && result.isAiEvaluated) {
          completer.complete(result);
        } else {
          pending--;
          if (pending == 0 && !completer.isCompleted) {
            completer.complete(result);
          }
        }
      }).catchError((_) {
        pending--;
        if (pending == 0 && !completer.isCompleted) {
          completer.complete(null);
        }
      });
    }

    return completer.future;
  }
}

