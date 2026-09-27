import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/topic_entity.dart';
import '../entities/cue_card_entity.dart';
import '../entities/question_entity.dart';
import '../entities/vocabulary_entity.dart';
import '../entities/mock_evaluation_entity.dart';

abstract class SpeakingRepository {
  Future<Either<Failure, List<TopicEntity>>> getPart1Topics();
  Future<Either<Failure, List<CueCardEntity>>> getCueCards();
  Future<Either<Failure, CueCardEntity>> getCueCardById(String id);
  Future<Either<Failure, List<QuestionEntity>>> getQuestionsByTopic(String topicId);
  Future<Either<Failure, List<VocabularyEntity>>> getVocabularyItems({String? category});
  Future<Either<Failure, bool>> toggleBookmark(String itemId, bool currentStatus);
  Future<Either<Failure, List<String>>> getBookmarkedIds();
  Future<Either<Failure, MockEvaluationEntity>> submitMockTestEvaluation({
    required String testTitle,
    required int durationSeconds,
  });
  Future<Either<Failure, List<MockEvaluationEntity>>> getMockTestHistory();
}
