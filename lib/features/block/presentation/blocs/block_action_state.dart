import 'package:equatable/equatable.dart';

/// One-shot outcome of a block action. [success] means the target should be
/// removed from the caller's view (also used for the neutral
/// TARGET_USER_NOT_FOUND case — never reveal block status).
enum BlockActionOutcome { none, success, failure }

class BlockActionState extends Equatable {
  final bool blocking;
  final BlockActionOutcome outcome;
  final int eventVersion;
  final String? blockedUserId;
  final String? messageKey;

  const BlockActionState({
    this.blocking = false,
    this.outcome = BlockActionOutcome.none,
    this.eventVersion = 0,
    this.blockedUserId,
    this.messageKey,
  });

  BlockActionState copyWith({
    bool? blocking,
    BlockActionOutcome? outcome,
    int? eventVersion,
    String? blockedUserId,
    String? messageKey,
  }) {
    return BlockActionState(
      blocking: blocking ?? this.blocking,
      outcome: outcome ?? this.outcome,
      eventVersion: eventVersion ?? this.eventVersion,
      blockedUserId: blockedUserId ?? this.blockedUserId,
      messageKey: messageKey ?? this.messageKey,
    );
  }

  @override
  List<Object?> get props =>
      [blocking, outcome, eventVersion, blockedUserId, messageKey];
}
