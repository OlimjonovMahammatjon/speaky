import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/question_entity.dart';
import '../repositories/speaking_repository.dart';

class GetQuestionsByTopicParams extends Equatable {
  final String topicId;
  const GetQuestionsByTopicParams({required this.topicId});

  @override
  List<Object?> get props => [topicId];
}

class GetQuestionsByTopicUseCase implements UseCase<List<QuestionEntity>, GetQuestionsByTopicParams> {
  final SpeakingRepository repository;

  GetQuestionsByTopicUseCase(this.repository);

  @override
  Future<Either<Failure, List<QuestionEntity>>> call(GetQuestionsByTopicParams params) async {
    return await repository.getQuestionsByTopic(params.topicId);
  }
}
