import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/cue_card_entity.dart';
import '../../domain/entities/topic_entity.dart';
import '../../domain/entities/vocabulary_entity.dart';
import '../../domain/usecases/get_part1_topics_usecase.dart';
import '../../domain/usecases/get_cue_cards_usecase.dart';
import '../../domain/usecases/get_vocabulary_list_usecase.dart';
import '../../domain/usecases/toggle_bookmark_usecase.dart';
import 'speaking_event.dart';
import 'speaking_state.dart';

export 'speaking_event.dart';
export 'speaking_state.dart';

class SpeakingBloc extends Bloc<SpeakingEvent, SpeakingState> {
  final GetPart1TopicsUseCase getPart1TopicsUseCase;
  final GetCueCardsUseCase getCueCardsUseCase;
  final GetVocabularyListUseCase getVocabularyListUseCase;
  final ToggleBookmarkUseCase toggleBookmarkUseCase;

  SpeakingBloc({
    required this.getPart1TopicsUseCase,
    required this.getCueCardsUseCase,
    required this.getVocabularyListUseCase,
    required this.toggleBookmarkUseCase,
  }) : super(SpeakingInitial()) {
    on<LoadSpeakingDataEvent>(_onLoadSpeakingData);
    on<FilterTopicsByCategoryEvent>(_onFilterTopicsByCategory);
    on<ToggleTopicBookmarkEvent>(_onToggleTopicBookmark);
    on<ToggleCueCardBookmarkEvent>(_onToggleCueCardBookmark);
    on<LoadVocabularyEvent>(_onLoadVocabulary);
  }

  Future<void> _onLoadSpeakingData(
    LoadSpeakingDataEvent event,
    Emitter<SpeakingState> emit,
  ) async {
    // Only emit Loading if state is not already loaded (smooth transition)
    if (state is! SpeakingLoaded) {
      emit(SpeakingLoading());
    }

    // Parallel fetch for optimal speed and zero sequential latency
    final results = await Future.wait([
      getPart1TopicsUseCase(NoParams()),
      getCueCardsUseCase(NoParams()),
      getVocabularyListUseCase(null),
    ]);

    final topicsResult = results[0] as Either<Failure, List<TopicEntity>>;
    final cueCardsResult = results[1] as Either<Failure, List<CueCardEntity>>;
    final vocabResult = results[2] as Either<Failure, List<VocabularyEntity>>;

    final topics = topicsResult.getOrElse(() => []);
    final cueCards = cueCardsResult.getOrElse(() => []);
    final vocab = vocabResult.getOrElse(() => []);

    if (topics.isEmpty && cueCards.isEmpty && vocab.isEmpty) {
      final errorMsg = topicsResult.fold((f) => f.message, (_) => 'Failed to load speaking practice data');
      emit(SpeakingError(errorMsg));
    } else {
      emit(SpeakingLoaded(
        allTopics: topics,
        filteredTopics: topics,
        cueCards: cueCards,
        vocabularyItems: vocab,
        selectedCategory: 'All',
      ));
    }
  }

  void _onFilterTopicsByCategory(
    FilterTopicsByCategoryEvent event,
    Emitter<SpeakingState> emit,
  ) {
    if (state is SpeakingLoaded) {
      final currentState = state as SpeakingLoaded;
      if (event.categoryName == 'All') {
        emit(currentState.copyWith(
          filteredTopics: currentState.allTopics,
          selectedCategory: 'All',
        ));
      } else {
        final filtered = currentState.allTopics.where((t) {
          return t.category.name.toLowerCase() == event.categoryName.toLowerCase();
        }).toList();
        emit(currentState.copyWith(
          filteredTopics: filtered,
          selectedCategory: event.categoryName,
        ));
      }
    }
  }

  Future<void> _onToggleTopicBookmark(
    ToggleTopicBookmarkEvent event,
    Emitter<SpeakingState> emit,
  ) async {
    if (state is SpeakingLoaded) {
      final currentState = state as SpeakingLoaded;
      final result = await toggleBookmarkUseCase(ToggleBookmarkParams(
        itemId: event.topicId,
        currentStatus: event.currentStatus,
      ));

      result.fold(
        (failure) {},
        (newStatus) {
          final updatedAll = currentState.allTopics.map((topic) {
            if (topic.id == event.topicId) {
              return topic.copyWith(isBookmarked: newStatus);
            }
            return topic;
          }).toList();

          final updatedFiltered = currentState.filteredTopics.map((topic) {
            if (topic.id == event.topicId) {
              return topic.copyWith(isBookmarked: newStatus);
            }
            return topic;
          }).toList();

          emit(currentState.copyWith(
            allTopics: updatedAll,
            filteredTopics: updatedFiltered,
          ));
        },
      );
    }
  }

  Future<void> _onToggleCueCardBookmark(
    ToggleCueCardBookmarkEvent event,
    Emitter<SpeakingState> emit,
  ) async {
    if (state is SpeakingLoaded) {
      final currentState = state as SpeakingLoaded;
      final result = await toggleBookmarkUseCase(ToggleBookmarkParams(
        itemId: event.cueCardId,
        currentStatus: event.currentStatus,
      ));

      result.fold(
        (failure) {},
        (newStatus) {
          final updatedCueCards = currentState.cueCards.map((cueCard) {
            if (cueCard.id == event.cueCardId) {
              return cueCard.copyWith(isBookmarked: newStatus);
            }
            return cueCard;
          }).toList();

          emit(currentState.copyWith(cueCards: updatedCueCards));
        },
      );
    }
  }

  Future<void> _onLoadVocabulary(
    LoadVocabularyEvent event,
    Emitter<SpeakingState> emit,
  ) async {
    if (state is SpeakingLoaded) {
      final currentState = state as SpeakingLoaded;
      final result = await getVocabularyListUseCase(event.category);
      result.fold(
        (failure) {},
        (vocab) => emit(currentState.copyWith(vocabularyItems: vocab)),
      );
    }
  }
}
