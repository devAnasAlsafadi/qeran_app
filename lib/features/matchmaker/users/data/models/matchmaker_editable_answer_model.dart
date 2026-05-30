import '../../../shared/data/json_parsers.dart';
import '../../domain/entities/matchmaker_editable_answer.dart';

/// Wire model for one editable answer item:
/// `{ questionId:int, question:string, currentAnswer:string }`.
class MatchmakerEditableAnswerModel {
  final int questionId;
  final String question;
  final String currentAnswer;

  const MatchmakerEditableAnswerModel({
    required this.questionId,
    required this.question,
    required this.currentAnswer,
  });

  factory MatchmakerEditableAnswerModel.fromJson(Map<String, dynamic> json) =>
      MatchmakerEditableAnswerModel(
        questionId: parseInt(json['questionId']),
        question: parseString(json['question']),
        currentAnswer: parseString(json['currentAnswer']),
      );

  MatchmakerEditableAnswer toEntity() => MatchmakerEditableAnswer(
        questionId: questionId,
        question: question,
        currentAnswer: currentAnswer,
      );
}
