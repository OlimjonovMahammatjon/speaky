import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/cue_card_entity.dart';
import '../../domain/entities/mock_evaluation_entity.dart';
import '../../domain/entities/question_entity.dart';
import '../../domain/entities/topic_entity.dart';
import '../../domain/entities/vocabulary_entity.dart';
import '../../domain/repositories/speaking_repository.dart';
import '../datasources/speaking_local_data_source.dart';
import '../datasources/speaking_remote_data_source.dart';
import '../models/mock_evaluation_model.dart';

class SpeakingRepositoryImpl implements SpeakingRepository {
  final SpeakingLocalDataSource localDataSource;
  final SpeakingRemoteDataSource? remoteDataSource;

  SpeakingRepositoryImpl({
    required this.localDataSource,
    this.remoteDataSource,
  });

  @override
  Future<Either<Failure, List<TopicEntity>>> getPart1Topics() async {
    // Try remote (Supabase) if available, otherwise fallback to local
    if (remoteDataSource != null) {
      try {
        final remoteTopics = await remoteDataSource!.getPart1Topics();
        if (remoteTopics.isNotEmpty) {
          // Cache remote data for offline use
          await localDataSource.cacheTopics(remoteTopics);
          final bookmarks = await localDataSource.getBookmarkedIds();
          final updatedWithBookmarks = remoteTopics.map((t) {
            return t.copyWith(isBookmarked: bookmarks.contains(t.id));
          }).toList();
          return Right(updatedWithBookmarks);
        }
      } catch (_) {
        // Fallback to local
      }
    }

    try {
      final topics = await localDataSource.getPart1Topics();
      return Right(topics);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CueCardEntity>>> getCueCards() async {
    if (remoteDataSource != null) {
      try {
        final remoteCards = await remoteDataSource!.getCueCards();
        if (remoteCards.isNotEmpty) {
          // Cache remote data for offline use
          await localDataSource.cacheCueCards(remoteCards);
          final bookmarks = await localDataSource.getBookmarkedIds();
          final updatedWithBookmarks = remoteCards.map((c) {
            return c.copyWith(isBookmarked: bookmarks.contains(c.id));
          }).toList();
          return Right(updatedWithBookmarks);
        }
      } catch (_) {
        // Fallback to local
      }
    }

    try {
      final cueCards = await localDataSource.getCueCards();
      return Right(cueCards);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CueCardEntity>> getCueCardById(String id) async {
    try {
      final cueCard = await localDataSource.getCueCardById(id);
      return Right(cueCard);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<QuestionEntity>>> getQuestionsByTopic(String topicId) async {
    if (remoteDataSource != null) {
      try {
        final remoteQuestions = await remoteDataSource!.getQuestionsByTopic(topicId);
        if (remoteQuestions.isNotEmpty) {
          // Cache for offline use
          await localDataSource.cacheQuestions(topicId, remoteQuestions);
          return Right(remoteQuestions);
        }
      } catch (_) {
        // Fallback
      }
    }

    try {
      final questions = await localDataSource.getQuestionsByTopic(topicId);
      return Right(questions);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VocabularyEntity>>> getVocabularyItems({String? category}) async {
    if (remoteDataSource != null) {
      try {
        final remoteVocab = await remoteDataSource!.getVocabularyItems(category: category);
        if (remoteVocab.isNotEmpty) {
          // Cache for offline use
          await localDataSource.cacheVocabulary(remoteVocab);
          return Right(remoteVocab);
        }
      } catch (_) {
        // Fallback
      }
    }

    try {
      final items = await localDataSource.getVocabularyItems(category: category);
      return Right(items);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> toggleBookmark(String itemId, bool currentStatus) async {
    try {
      final newStatus = await localDataSource.toggleBookmark(itemId, currentStatus);
      return Right(newStatus);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getBookmarkedIds() async {
    try {
      final ids = await localDataSource.getBookmarkedIds();
      return Right(ids);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MockEvaluationEntity>> submitMockTestEvaluation({
    required String testTitle,
    required int durationSeconds,
  }) async {
    try {
      final evaluation = _generateEvaluation(testTitle, durationSeconds);
      final saved = await localDataSource.saveMockTestEvaluation(evaluation);
      return Right(saved);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  /// Generates a practice evaluation based on speaking duration.
  ///
  /// NOTE: This is a DEMO evaluation — real speech analysis requires
  /// audio recording + AI evaluation (e.g. Supabase Edge Function
  /// calling OpenAI Whisper). The score is estimated from duration
  /// and is clearly labeled as "Practice Mode" in the UI.
  MockEvaluationModel _generateEvaluation(String testTitle, int durationSeconds) {
    // Duration-based scoring: longer speech = better fluency signal
    final fluency = _scoreFromDuration(durationSeconds, 6.0, 7.0, 8.0);
    final lexical = _scoreFromDuration(durationSeconds, 6.5, 7.5, 8.5);
    final grammar = _scoreFromDuration(durationSeconds, 6.0, 7.0, 8.0);
    final pronunciation = _scoreFromDuration(durationSeconds, 6.5, 7.5, 8.5);

    final rawOverall = (fluency + lexical + grammar + pronunciation) / 4.0;
    final overall = (rawOverall * 2).round() / 2.0;

    final strengths = <String>[
      if (durationSeconds >= 90)
        'You sustained speech for $durationSeconds seconds — good stamina and fluency.'
      else if (durationSeconds >= 60)
        'You spoke for $durationSeconds seconds — solid effort on maintaining flow.'
      else
        'You completed the practice session ($durationSeconds seconds). Keep extending your answers!',
      'Effective utilization of natural discourse markers and cohesive linkers.',
      'Good pacing and intonation on key stressed words.',
    ];

    final areasToImprove = <String>[
      'Incorporate more inverted conditionals (e.g. "Were I to...", "Had I known...") for grammar diversity.',
      if (durationSeconds < 90)
        'Aim to speak for the full 2 minutes — extend your answer with an anecdote or example.',
      'Practice paraphrasing examiner prompts rather than repeating them directly.',
    ];

    return MockEvaluationModel(
      id: 'eval_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      overallBand: overall,
      fluencyBand: (fluency * 2).round() / 2.0,
      lexicalBand: (lexical * 2).round() / 2.0,
      grammarBand: (grammar * 2).round() / 2.0,
      pronunciationBand: (pronunciation * 2).round() / 2.0,
      feedbackSummary: 'Practice Mode: This is an estimated score based on your speaking '
          'duration ($durationSeconds seconds). For a full AI evaluation, connect a speech '
          'analysis service. Your dedication to daily practice is the real win!',
      strengths: strengths,
      areasToImprove: areasToImprove,
    );
  }

  /// Maps a speaking duration to a band score.
  /// [minVal] = spoken < 30s, [midVal] = 30–90s, [maxVal] = 90–120s.
  double _scoreFromDuration(int seconds, double minVal, double midVal, double maxVal) {
    if (seconds < 30) return minVal;
    if (seconds < 90) return midVal;
    return maxVal;
  }

  @override
  Future<Either<Failure, List<MockEvaluationEntity>>> getMockTestHistory() async {
    try {
      final evaluations = await localDataSource.getMockTestEvaluations();
      return Right(evaluations);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
