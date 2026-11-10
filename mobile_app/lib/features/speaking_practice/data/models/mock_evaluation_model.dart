import '../../domain/entities/mock_evaluation_entity.dart';

class MockEvaluationModel extends MockEvaluationEntity {
  const MockEvaluationModel({
    required super.id,
    required super.date,
    required super.overallBand,
    required super.fluencyBand,
    required super.lexicalBand,
    required super.grammarBand,
    required super.pronunciationBand,
    required super.feedbackSummary,
    required super.strengths,
    required super.areasToImprove,
    super.isAiEvaluated = false,
    super.transcription,
  });

  factory MockEvaluationModel.fromJson(Map<String, dynamic> json) {
    return MockEvaluationModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      overallBand: (json['overallBand'] as num).toDouble(),
      fluencyBand: (json['fluencyBand'] as num).toDouble(),
      lexicalBand: (json['lexicalBand'] as num).toDouble(),
      grammarBand: (json['grammarBand'] as num).toDouble(),
      pronunciationBand: (json['pronunciationBand'] as num).toDouble(),
      feedbackSummary: json['feedbackSummary'] as String,
      strengths: List<String>.from(json['strengths'] as List),
      areasToImprove: List<String>.from(json['areasToImprove'] as List),
      isAiEvaluated: json['isAiEvaluated'] as bool? ?? false,
      transcription: json['transcription'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'overallBand': overallBand,
      'fluencyBand': fluencyBand,
      'lexicalBand': lexicalBand,
      'grammarBand': grammarBand,
      'pronunciationBand': pronunciationBand,
      'feedbackSummary': feedbackSummary,
      'strengths': strengths,
      'areasToImprove': areasToImprove,
      'isAiEvaluated': isAiEvaluated,
      if (transcription != null) 'transcription': transcription,
    };
  }
}
