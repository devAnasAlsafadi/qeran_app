import '../../domain/entities/shared_profile_answer.dart';
import '../json_parsers.dart';

class SharedProfileAnswerModel {
  final int questionId;
  final String question;
  final String answer;

  const SharedProfileAnswerModel({
    required this.questionId,
    required this.question,
    required this.answer,
  });

  factory SharedProfileAnswerModel.fromJson(Map<String, dynamic> json) {
    return SharedProfileAnswerModel(
      questionId: parseInt(json['questionId']),
      question: parseString(json['question']),
      answer: parseString(json['answer']),
    );
  }

  SharedProfileAnswer toEntity() => SharedProfileAnswer(
        questionId: questionId,
        question: question,
        answer: answer,
      );
}
