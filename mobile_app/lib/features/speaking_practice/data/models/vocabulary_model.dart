import '../../domain/entities/vocabulary_entity.dart';

class VocabularyModel extends VocabularyEntity {
  const VocabularyModel({
    required super.id,
    required super.phrase,
    required super.phonetics,
    required super.type,
    required super.meaning,
    required super.bandTarget,
    required super.exampleIeltsContext,
    required super.topicTag,
  });

  factory VocabularyModel.fromJson(Map<String, dynamic> json) {
    return VocabularyModel(
      id: json['id'].toString(),
      phrase: (json['phrase'] ?? '') as String,
      phonetics: (json['phonetics'] ?? '') as String,
      type: VocabularyType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'collocation'),
        orElse: () => VocabularyType.collocation,
      ),
      meaning: (json['meaning'] ?? '') as String,
      bandTarget: (json['band_target'] ?? json['bandTarget'] ?? 'Band 8.0+') as String,
      exampleIeltsContext:
          (json['example_ielts_context'] ?? json['exampleIeltsContext'] ?? '') as String,
      topicTag: (json['topic_tag'] ?? json['topicTag'] ?? 'General') as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phrase': phrase,
      'phonetics': phonetics,
      'type': type.name,
      'meaning': meaning,
      'bandTarget': bandTarget,
      'exampleIeltsContext': exampleIeltsContext,
      'topicTag': topicTag,
    };
  }
}
