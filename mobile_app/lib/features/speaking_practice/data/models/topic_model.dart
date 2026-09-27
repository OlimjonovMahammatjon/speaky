import '../../domain/entities/topic_entity.dart';

class TopicModel extends TopicEntity {
  const TopicModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.partNumber,
    required super.questionsCount,
    super.bandTarget,
    super.isBookmarked,
    super.iconCode,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'].toString(),
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      category: TopicCategory.values.firstWhere(
        (e) => e.name == (json['category'] ?? 'technology'),
        orElse: () => TopicCategory.technology,
      ),
      partNumber: (json['part_number'] ?? json['partNumber'] ?? 1) as int,
      questionsCount: (json['questions_count'] ?? json['questionsCount'] ?? 4) as int,
      bandTarget: (json['band_target'] ?? json['bandTarget'] ?? '7.5+') as String,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      iconCode: (json['icon_code'] ?? json['iconCode'] ?? 'chat') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category.name,
      'partNumber': partNumber,
      'questionsCount': questionsCount,
      'bandTarget': bandTarget,
      'isBookmarked': isBookmarked,
      'iconCode': iconCode,
    };
  }

  factory TopicModel.fromEntity(TopicEntity entity) {
    return TopicModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      partNumber: entity.partNumber,
      questionsCount: entity.questionsCount,
      bandTarget: entity.bandTarget,
      isBookmarked: entity.isBookmarked,
      iconCode: entity.iconCode,
    );
  }
}
