import 'package:equatable/equatable.dart';
import '../../domain/entities/cue_card_entity.dart';
import '../../domain/entities/topic_entity.dart';
import '../../domain/entities/vocabulary_entity.dart';

abstract class SpeakingState extends Equatable {
  const SpeakingState();

  @override
  List<Object?> get props => [];
}

class SpeakingInitial extends SpeakingState {}

class SpeakingLoading extends SpeakingState {}

class SpeakingLoaded extends SpeakingState {
  final List<TopicEntity> allTopics;
  final List<TopicEntity> filteredTopics;
  final List<CueCardEntity> cueCards;
  final List<VocabularyEntity> vocabularyItems;
  final String selectedCategory;

  const SpeakingLoaded({
    required this.allTopics,
    required this.filteredTopics,
    required this.cueCards,
    required this.vocabularyItems,
    this.selectedCategory = 'All',
  });

  SpeakingLoaded copyWith({
    List<TopicEntity>? allTopics,
    List<TopicEntity>? filteredTopics,
    List<CueCardEntity>? cueCards,
    List<VocabularyEntity>? vocabularyItems,
    String? selectedCategory,
  }) {
    return SpeakingLoaded(
      allTopics: allTopics ?? this.allTopics,
      filteredTopics: filteredTopics ?? this.filteredTopics,
      cueCards: cueCards ?? this.cueCards,
      vocabularyItems: vocabularyItems ?? this.vocabularyItems,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  @override
  List<Object?> get props => [
        allTopics,
        filteredTopics,
        cueCards,
        vocabularyItems,
        selectedCategory,
      ];
}

class SpeakingError extends SpeakingState {
  final String message;
  const SpeakingError(this.message);

  @override
  List<Object?> get props => [message];
}
