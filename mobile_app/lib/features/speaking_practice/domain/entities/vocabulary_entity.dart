import 'package:equatable/equatable.dart';

enum VocabularyType {
  idiom,
  collocation,
  discourseMarker,
  academicLexis,
}

class VocabularyEntity extends Equatable {
  final String id;
  final String phrase;
  final String phonetics;
  final VocabularyType type;
  final String meaning;
  final String bandTarget; // e.g. "Band 8.0+"
  final String exampleIeltsContext;
  final String topicTag;

  const VocabularyEntity({
    required this.id,
    required this.phrase,
    required this.phonetics,
    required this.type,
    required this.meaning,
    required this.bandTarget,
    required this.exampleIeltsContext,
    required this.topicTag,
  });

  @override
  List<Object?> get props => [
        id,
        phrase,
        phonetics,
        type,
        meaning,
        bandTarget,
        exampleIeltsContext,
        topicTag,
      ];
}
