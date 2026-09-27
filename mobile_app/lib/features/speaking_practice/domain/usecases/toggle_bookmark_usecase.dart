import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/speaking_repository.dart';

class ToggleBookmarkParams extends Equatable {
  final String itemId;
  final bool currentStatus;

  const ToggleBookmarkParams({required this.itemId, required this.currentStatus});

  @override
  List<Object?> get props => [itemId, currentStatus];
}

class ToggleBookmarkUseCase implements UseCase<bool, ToggleBookmarkParams> {
  final SpeakingRepository repository;

  ToggleBookmarkUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ToggleBookmarkParams params) async {
    return await repository.toggleBookmark(params.itemId, params.currentStatus);
  }
}
