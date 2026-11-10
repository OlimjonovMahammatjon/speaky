import 'package:equatable/equatable.dart';

class MockEvaluationEntity extends Equatable {
  final String id;
  final DateTime date;
  final double overallBand;
  final double fluencyBand;
  final double lexicalBand;
  final double grammarBand;
  final double pronunciationBand;
  final String feedbackSummary;
  final List<String> strengths;
  final List<String> areasToImprove;
  final bool isAiEvaluated;
  final String? transcription;

  const MockEvaluationEntity({
    required this.id,
    required this.date,
    required this.overallBand,
    required this.fluencyBand,
    required this.lexicalBand,
    required this.grammarBand,
    required this.pronunciationBand,
    required this.feedbackSummary,
    required this.strengths,
    required this.areasToImprove,
    this.isAiEvaluated = false,
    this.transcription,
  });

  @override
  List<Object?> get props => [
        id,
        date,
        overallBand,
        fluencyBand,
        lexicalBand,
        grammarBand,
        pronunciationBand,
        feedbackSummary,
        strengths,
        areasToImprove,
        isAiEvaluated,
        transcription,
      ];
}
