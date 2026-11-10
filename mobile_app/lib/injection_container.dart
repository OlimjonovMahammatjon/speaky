import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/network/supabase_config.dart';
import 'core/services/ai_speaking_service.dart';
import 'core/services/audio_recording_service.dart';
import 'core/services/dictaphone_service.dart';
import 'core/services/gemini_speaking_service.dart';
import 'core/services/groq_speaking_service.dart';
import 'core/services/notification_service.dart';
import 'features/speaking_practice/data/datasources/speaking_local_data_source.dart';
import 'features/speaking_practice/data/datasources/speaking_remote_data_source.dart';
import 'features/speaking_practice/data/repositories/speaking_repository_impl.dart';
import 'features/speaking_practice/domain/repositories/speaking_repository.dart';
import 'features/speaking_practice/domain/usecases/get_part1_topics_usecase.dart';
import 'features/speaking_practice/domain/usecases/get_cue_cards_usecase.dart';
import 'features/speaking_practice/domain/usecases/get_questions_by_topic_usecase.dart';
import 'features/speaking_practice/domain/usecases/get_vocabulary_list_usecase.dart';
import 'features/speaking_practice/domain/usecases/toggle_bookmark_usecase.dart';
import 'features/speaking_practice/presentation/bloc/speaking_bloc.dart';
import 'features/speaking_practice/presentation/bloc/mock_test_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! External - Supabase (safe initialization)
  if (SupabaseConfig.isConfigured()) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabaseAnonKey,
      );
    } catch (_) {
      // Ignored if credentials are placeholders or offline
    }
  }

  //! External - SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  //! Core services
  sl.registerLazySingleton<AudioRecordingService>(
    () => AudioRecordingService(),
  );

  sl.registerLazySingleton<DictaphoneService>(
    () => DictaphoneService(),
  );

  sl.registerLazySingleton<NotificationService>(
    () => NotificationService(),
  );

  sl.registerLazySingleton<GeminiSpeakingService>(
    () => GeminiSpeakingService(),
  );

  sl.registerLazySingleton<GroqSpeakingService>(
    () => GroqSpeakingService(),
  );

  sl.registerLazySingleton<AiSpeakingService>(
    () => AiSpeakingService(
      geminiService: sl(),
      groqService: sl(),
    ),
  );

  //! Features - Speaking Practice
  // Bloc
  sl.registerFactory(
    () => SpeakingBloc(
      getPart1TopicsUseCase: sl(),
      getCueCardsUseCase: sl(),
      getVocabularyListUseCase: sl(),
      toggleBookmarkUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => MockTestBloc(
      repository: sl(),
      audioService: sl<AudioRecordingService>(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetPart1TopicsUseCase(sl()));
  sl.registerLazySingleton(() => GetCueCardsUseCase(sl()));
  sl.registerLazySingleton(() => GetQuestionsByTopicUseCase(sl()));
  sl.registerLazySingleton(() => GetVocabularyListUseCase(sl()));
  sl.registerLazySingleton(() => ToggleBookmarkUseCase(sl()));

  // Repositories
  sl.registerLazySingleton<SpeakingRepository>(
    () => SpeakingRepositoryImpl(
      localDataSource: sl(),
      remoteDataSource: sl(),
      aiService: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<SpeakingLocalDataSource>(
    () => SpeakingLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );

  sl.registerLazySingleton<SpeakingRemoteDataSource>(
    () => SpeakingRemoteDataSourceImpl(),
  );
}
