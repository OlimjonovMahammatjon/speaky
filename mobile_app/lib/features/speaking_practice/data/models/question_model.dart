import '../../domain/entities/question_entity.dart';

class QuestionModel extends QuestionEntity {
  const QuestionModel({
    required super.id,
    required super.topicId,
    required super.questionText,
    required super.sampleAnswerBand8,
    super.shortSampleAnswer,
    super.ideas,
    required super.highBandVocabulary,
    required super.examinerTips,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'].toString(),
      topicId: (json['topic_id'] ?? json['topicId'] ?? '') as String,
      questionText: (json['question_text'] ?? json['questionText']) as String,
      sampleAnswerBand8: (json['sample_answer_band8'] ?? json['sampleAnswerBand8'] ?? '') as String,
      shortSampleAnswer: (json['short_sample_answer'] ?? json['shortSampleAnswer'] ?? '') as String,
      ideas: json['ideas'] != null
          ? List<String>.from(json['ideas'] as List)
          : const [],
      highBandVocabulary: json['high_band_vocabulary'] != null
          ? List<String>.from(json['high_band_vocabulary'] as List)
          : json['highBandVocabulary'] != null
              ? List<String>.from(json['highBandVocabulary'] as List)
              : const [],
      examinerTips: json['examiner_tips'] != null
          ? List<String>.from(json['examiner_tips'] as List)
          : json['examinerTips'] != null
              ? List<String>.from(json['examinerTips'] as List)
              : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic_id': topicId,
      'question_text': questionText,
      'sample_answer_band8': sampleAnswerBand8,
      'short_sample_answer': shortSampleAnswer,
      'ideas': ideas,
      'high_band_vocabulary': highBandVocabulary,
      'examiner_tips': examinerTips,
    };
  }
}
