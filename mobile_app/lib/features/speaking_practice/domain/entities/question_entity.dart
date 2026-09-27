import 'package:equatable/equatable.dart';

class QuestionEntity extends Equatable {
  final String id;
  final String topicId;
  final String questionText;
  final String sampleAnswerBand8;
  final String shortSampleAnswer;
  final List<String> ideas; // Brainstorming ideas & answering angles
  final List<String> highBandVocabulary;
  final List<String> examinerTips;

  const QuestionEntity({
    required this.id,
    required this.topicId,
    required this.questionText,
    required this.sampleAnswerBand8,
    this.shortSampleAnswer = '',
    this.ideas = const [],
    required this.highBandVocabulary,
    required this.examinerTips,
  });

  @override
  List<Object?> get props => [
        id,
        topicId,
        questionText,
        sampleAnswerBand8,
        shortSampleAnswer,
        ideas,
        highBandVocabulary,
        examinerTips,
      ];
}
