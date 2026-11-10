import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static String get supabaseUrl {
    // 1. Check flutter_dotenv (.env file)
    final fromDotenv = dotenv.maybeGet('SUPABASE_URL');
    if (fromDotenv != null && fromDotenv.trim().isNotEmpty) {
      return fromDotenv.trim();
    }

    // 2. Check --dart-define build flags
    const fromDefine = String.fromEnvironment('SUPABASE_URL');
    if (fromDefine.isNotEmpty) {
      return fromDefine.trim();
    }

    return '';
  }

  static String get supabaseAnonKey {
    // 1. Check flutter_dotenv (.env file)
    final fromDotenv = dotenv.maybeGet('SUPABASE_ANON_KEY');
    if (fromDotenv != null && fromDotenv.trim().isNotEmpty) {
      return fromDotenv.trim();
    }

    // 2. Check --dart-define build flags
    const fromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromDefine.isNotEmpty) {
      return fromDefine.trim();
    }

    return '';
  }

  // Dynamic keys fetched from Supabase app_settings table or local cache
  static String? _dynamicGeminiKey;
  static String? _dynamicGroqKey;
  static String? _dynamicAiProvider;

  static void setDynamicConfig({String? geminiKey, String? groqKey, String? aiProvider}) {
    if (geminiKey != null && geminiKey.isNotEmpty) _dynamicGeminiKey = geminiKey;
    if (groqKey != null && groqKey.isNotEmpty) _dynamicGroqKey = groqKey;
    if (aiProvider != null && aiProvider.isNotEmpty) _dynamicAiProvider = aiProvider;
  }

  static String get geminiApiKey {
    if (_dynamicGeminiKey != null && _dynamicGeminiKey!.isNotEmpty) {
      return _dynamicGeminiKey!;
    }
    final fromDotenv = dotenv.maybeGet('GEMINI_API_KEY');
    if (fromDotenv != null && fromDotenv.trim().isNotEmpty) {
      return fromDotenv.trim();
    }
    const fromDefine = String.fromEnvironment('GEMINI_API_KEY');
    if (fromDefine.isNotEmpty) {
      return fromDefine.trim();
    }
    return '';
  }

  static String get groqApiKey {
    if (_dynamicGroqKey != null && _dynamicGroqKey!.isNotEmpty) {
      return _dynamicGroqKey!;
    }
    final fromDotenv = dotenv.maybeGet('GROQ_API_KEY');
    if (fromDotenv != null && fromDotenv.trim().isNotEmpty) {
      return fromDotenv.trim();
    }
    const fromDefine = String.fromEnvironment('GROQ_API_KEY');
    if (fromDefine.isNotEmpty) {
      return fromDefine.trim();
    }
    return '';
  }

  static String get activeAiProvider {
    return _dynamicAiProvider ?? 'auto';
  }

  static bool get isGeminiConfigured =>
      geminiApiKey.isNotEmpty && !geminiApiKey.contains('your-key');

  static bool get isGroqConfigured =>
      groqApiKey.isNotEmpty && !groqApiKey.contains('your-key');

  static bool isConfigured() {
    final url = supabaseUrl;
    final key = supabaseAnonKey;

    if (url.isEmpty || key.isEmpty) return false;
    if (url.contains('your-project-id') || key.contains('your-anon-key-here')) return false;
    if (!url.startsWith('https://')) return false;

    return true;
  }

  static SupabaseClient? get client {
    if (isConfigured()) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
