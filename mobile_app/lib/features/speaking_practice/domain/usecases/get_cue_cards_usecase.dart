import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/cue_card_entity.dart';
import '../repositories/speaking_repository.dart';

class GetCueCardsUseCase implements UseCase<List<CueCardEntity>, NoParams> {
  final SpeakingRepository repository;

  GetCueCardsUseCase(this.repository);

  @override
  Future<Either<Failure, List<CueCardEntity>>> call(NoParams params) async {
    return await repository.getCueCards();
  }
}
