import 'package:equatable/equatable.dart';

/// One editable text answer on a user's profile, as returned by
/// `GET /matchmaker/users/{id}/editable-answers`. The endpoint already
/// returns only Text-type questions, so no further filtering is needed.
class MatchmakerEditableAnswer extends Equatable {
  final int questionId;
  final String question;
  final String currentAnswer;

  const MatchmakerEditableAnswer({
    required this.questionId,
    required this.question,
    required this.currentAnswer,
  });

  MatchmakerEditableAnswer copyWith({String? currentAnswer}) =>
      MatchmakerEditableAnswer(
        questionId: questionId,
        question: question,
        currentAnswer: currentAnswer ?? this.currentAnswer,
      );

  @override
  List<Object?> get props => [questionId, question, currentAnswer];
}
