import 'package:equatable/equatable.dart';

/// One admin-flagged answer surfaced on a matchmaker user-list card, as
/// returned in the `answers[]` array of `MatchmakerUserCardDto`
/// (`{ questionId, question, answer }`). Read-only on the card — distinct
/// from [MatchmakerEditableAnswer] (whose field is `currentAnswer` and which
/// powers the editable-answers screen). The list is `[]`, never null, when
/// no answers are flagged; order is admin-driven, not guaranteed.
class MatchmakerCardAnswer extends Equatable {
  final int questionId;
  final String question;
  final String answer;

  const MatchmakerCardAnswer({
    required this.questionId,
    required this.question,
    required this.answer,
  });

  @override
  List<Object?> get props => [questionId, question, answer];
}
