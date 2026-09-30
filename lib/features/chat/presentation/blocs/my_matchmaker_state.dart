import 'package:equatable/equatable.dart';

import '../../domain/entities/matchmaker_info.dart';

/// Who the member's matchmaker is, as the shell's top bar shows it.
///
/// Loading and failure are one state on purpose: the bar draws them the same
/// way (the role line alone), and a tap still opens the chat, whose own
/// screens tell the two apart.
sealed class MyMatchmakerState extends Equatable {
  const MyMatchmakerState();

  @override
  List<Object?> get props => const [];
}

/// Not known yet — the first read is in flight or failed.
final class MyMatchmakerUnknown extends MyMatchmakerState {
  const MyMatchmakerUnknown();
}

/// No matchmaker assigned yet.
final class MyMatchmakerNone extends MyMatchmakerState {
  const MyMatchmakerNone();
}

final class MyMatchmakerKnown extends MyMatchmakerState {
  final MatchmakerInfo info;
  const MyMatchmakerKnown(this.info);

  @override
  List<Object?> get props => [info];
}
