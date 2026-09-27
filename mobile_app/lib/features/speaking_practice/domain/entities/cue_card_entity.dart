import 'package:equatable/equatable.dart';

class CueCardEntity extends Equatable {
  final String id;
  final String title;
  final String topicArea;
  final String cuePrompt;
  final List<String> bulletPoints;
  final List<String> storyIdeas; // Multiple brainstorming story angles
  final String band9ModelAnswer;
  final String shortSampleAnswer; // Concise quick-glance sample answer
  final List<String> keyCollocations;
  final List<String> part3FollowUps;
  final bool isBookmarked;

  const CueCardEntity({
    required this.id,
    required this.title,
    required this.topicArea,
    required this.cuePrompt,
    required this.bulletPoints,
    this.storyIdeas = const [],
    required this.band9ModelAnswer,
    this.shortSampleAnswer = '',
    required this.keyCollocations,
    required this.part3FollowUps,
    this.isBookmarked = false,
  });

  CueCardEntity copyWith({
    String? id,
    String? title,
    String? topicArea,
    String? cuePrompt,
    List<String>? bulletPoints,
    List<String>? storyIdeas,
    String? band9ModelAnswer,
    String? shortSampleAnswer,
    List<String>? keyCollocations,
    List<String>? part3FollowUps,
    bool? isBookmarked,
  }) {
    return CueCardEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      topicArea: topicArea ?? this.topicArea,
      cuePrompt: cuePrompt ?? this.cuePrompt,
      bulletPoints: bulletPoints ?? this.bulletPoints,
      storyIdeas: storyIdeas ?? this.storyIdeas,
      band9ModelAnswer: band9ModelAnswer ?? this.band9ModelAnswer,
      shortSampleAnswer: shortSampleAnswer ?? this.shortSampleAnswer,
      keyCollocations: keyCollocations ?? this.keyCollocations,
      part3FollowUps: part3FollowUps ?? this.part3FollowUps,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        topicArea,
        cuePrompt,
        bulletPoints,
        storyIdeas,
        band9ModelAnswer,
        shortSampleAnswer,
        keyCollocations,
        part3FollowUps,
        isBookmarked,
      ];
}
