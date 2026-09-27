import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/vocabulary_entity.dart';
import '../repositories/speaking_repository.dart';

class GetVocabularyListUseCase implements UseCase<List<VocabularyEntity>, String?> {
  final SpeakingRepository repository;

  GetVocabularyListUseCase(this.repository);

  @override
  Future<Either<Failure, List<VocabularyEntity>>> call(String? category) async {
    return await repository.getVocabularyItems(category: category);
  }
}
