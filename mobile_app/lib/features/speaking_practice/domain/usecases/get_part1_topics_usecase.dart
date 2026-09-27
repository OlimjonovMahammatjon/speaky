import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/topic_entity.dart';
import '../repositories/speaking_repository.dart';

class GetPart1TopicsUseCase implements UseCase<List<TopicEntity>, NoParams> {
  final SpeakingRepository repository;

  GetPart1TopicsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TopicEntity>>> call(NoParams params) async {
    return await repository.getPart1Topics();
  }
}
