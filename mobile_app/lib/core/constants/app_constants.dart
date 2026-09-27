class AppConstants {
  AppConstants._();

  static const String appName = 'IELTS Speaky';
  static const String appTagline = 'Master IELTS Speaking with AI & Clean Architecture';

  // Test Structure Time limits (seconds)
  static const int part2PrepSeconds = 60; // 1 minute
  static const int part2SpeakingSeconds = 120; // 2 minutes

  // Band Score Descriptions
  static const Map<String, String> bandDescriptions = {
    '9.0': 'Expert Speaker - Fluent, accurate, sophisticated vocabulary.',
    '8.0': 'Very Good Speaker - Fluent with rare unsystematic inaccuracies.',
    '7.0': 'Good Speaker - Operational command with occasional inaccuracies.',
    '6.0': 'Competent Speaker - Effective command despite some inaccuracies.',
  };

  // 4 Assessment Criteria
  static const List<String> assessmentCriteria = [
    'Fluency & Coherence (FC)',
    'Lexical Resource (LR)',
    'Grammatical Range & Accuracy (GRA)',
    'Pronunciation (PR)',
  ];

  // SharedPreferences Keys
  static const String prefBookmarks = 'ielts_speaky_bookmarks';
  static const String prefCompletedTests = 'ielts_speaky_completed_tests';
  static const String prefUserTargetBand = 'ielts_speaky_target_band';
  static const String prefStreakCount = 'ielts_speaky_streak_count';
}
