import '../../domain/entities/cue_card_entity.dart';

class CueCardModel extends CueCardEntity {
  const CueCardModel({
    required super.id,
    required super.title,
    required super.topicArea,
    required super.cuePrompt,
    required super.bulletPoints,
    super.storyIdeas,
    required super.band9ModelAnswer,
    super.shortSampleAnswer,
    required super.keyCollocations,
    required super.part3FollowUps,
    super.isBookmarked,
  });

  factory CueCardModel.fromJson(Map<String, dynamic> json) {
    return CueCardModel(
      id: json['id'].toString(),
      title: json['title'] as String,
      topicArea: (json['topic_area'] ?? json['topicArea']) as String,
      cuePrompt: (json['cue_prompt'] ?? json['cuePrompt']) as String,
      bulletPoints: List<String>.from(json['bullet_points'] ?? json['bulletPoints'] ?? []),
      storyIdeas: json['story_ideas'] != null
          ? List<String>.from(json['story_ideas'] as List)
          : json['storyIdeas'] != null
              ? List<String>.from(json['storyIdeas'] as List)
              : const [],
      band9ModelAnswer: (json['band9_model_answer'] ?? json['band9ModelAnswer'] ?? '') as String,
      shortSampleAnswer: (json['short_sample_answer'] ?? json['shortSampleAnswer'] ?? '') as String,
      keyCollocations: List<String>.from(json['key_collocations'] ?? json['keyCollocations'] ?? []),
      part3FollowUps: List<String>.from(json['part3_follow_ups'] ?? json['part3FollowUps'] ?? []),
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'topic_area': topicArea,
      'cue_prompt': cuePrompt,
      'bullet_points': bulletPoints,
      'story_ideas': storyIdeas,
      'band9_model_answer': band9ModelAnswer,
      'short_sample_answer': shortSampleAnswer,
      'key_collocations': keyCollocations,
      'part3_follow_ups': part3FollowUps,
      'isBookmarked': isBookmarked,
    };
  }

  factory CueCardModel.fromEntity(CueCardEntity entity) {
    return CueCardModel(
      id: entity.id,
      title: entity.title,
      topicArea: entity.topicArea,
      cuePrompt: entity.cuePrompt,
      bulletPoints: entity.bulletPoints,
      storyIdeas: entity.storyIdeas,
      band9ModelAnswer: entity.band9ModelAnswer,
      shortSampleAnswer: entity.shortSampleAnswer,
      keyCollocations: entity.keyCollocations,
      part3FollowUps: entity.part3FollowUps,
      isBookmarked: entity.isBookmarked,
    );
  }
}
