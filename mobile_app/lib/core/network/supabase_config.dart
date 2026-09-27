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
