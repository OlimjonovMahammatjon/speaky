import 'package:equatable/equatable.dart';

abstract class SpeakingEvent extends Equatable {
  const SpeakingEvent();

  @override
  List<Object?> get props => [];
}

class LoadSpeakingDataEvent extends SpeakingEvent {
  const LoadSpeakingDataEvent();
}

class FilterTopicsByCategoryEvent extends SpeakingEvent {
  final String categoryName;
  const FilterTopicsByCategoryEvent(this.categoryName);

  @override
  List<Object?> get props => [categoryName];
}

class ToggleTopicBookmarkEvent extends SpeakingEvent {
  final String topicId;
  final bool currentStatus;

  const ToggleTopicBookmarkEvent({required this.topicId, required this.currentStatus});

  @override
  List<Object?> get props => [topicId, currentStatus];
}

class ToggleCueCardBookmarkEvent extends SpeakingEvent {
  final String cueCardId;
  final bool currentStatus;

  const ToggleCueCardBookmarkEvent({required this.cueCardId, required this.currentStatus});

  @override
  List<Object?> get props => [cueCardId, currentStatus];
}

class LoadVocabularyEvent extends SpeakingEvent {
  final String? category;
  const LoadVocabularyEvent({this.category});

  @override
  List<Object?> get props => [category];
}
