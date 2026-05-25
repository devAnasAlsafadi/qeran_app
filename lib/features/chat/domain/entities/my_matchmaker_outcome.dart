import 'matchmaker_info.dart';

/// Typed outcomes for `GET /api/chat/my-matchmaker`.
///
/// Backend uses `status: 0` (with no errorCode) to signal "user has
/// no matchmaker assigned yet" — a normal product state we render as
/// a calm empty card, NOT an error. We model it as its own outcome
/// so the cubit doesn't have to message-match.
sealed class MyMatchmakerOutcome {
  const MyMatchmakerOutcome();
}

final class MyMatchmakerAssigned extends MyMatchmakerOutcome {
  final MatchmakerInfo info;
  const MyMatchmakerAssigned({required this.info});
}

/// `status:0`, `data:null` — no matchmaker yet. Server message is
/// `لم يتم تعيين خطّابة لك بعد` but we render localized copy.
final class MyMatchmakerNotAssigned extends MyMatchmakerOutcome {
  final String serverMessage;
  const MyMatchmakerNotAssigned({required this.serverMessage});
}

final class MyMatchmakerFailure extends MyMatchmakerOutcome {
  final String serverMessage;
  final String? errorCode;
  const MyMatchmakerFailure({
    required this.serverMessage,
    required this.errorCode,
  });
}
