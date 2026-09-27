import 'package:equatable/equatable.dart';

enum TopicCategory {
  technology,
  workAndStudy,
  travelAndPlaces,
  environment,
  artAndCulture,
  societyAndPeople,
  hobbiesAndLifestyle,
}

class TopicEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final TopicCategory category;
  final int partNumber; // 1, 2, or 3
  final int questionsCount;
  final String bandTarget;
  final bool isBookmarked;
  final String iconCode;

  const TopicEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.partNumber,
    required this.questionsCount,
    this.bandTarget = '7.5+',
    this.isBookmarked = false,
    this.iconCode = 'chat',
  });

  TopicEntity copyWith({
    String? id,
    String? title,
    String? description,
    TopicCategory? category,
    int? partNumber,
    int? questionsCount,
    String? bandTarget,
    bool? isBookmarked,
    String? iconCode,
  }) {
    return TopicEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      partNumber: partNumber ?? this.partNumber,
      questionsCount: questionsCount ?? this.questionsCount,
      bandTarget: bandTarget ?? this.bandTarget,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      iconCode: iconCode ?? this.iconCode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        partNumber,
        questionsCount,
        bandTarget,
        isBookmarked,
        iconCode,
      ];
}
