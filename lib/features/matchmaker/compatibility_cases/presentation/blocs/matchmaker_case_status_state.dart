import 'package:equatable/equatable.dart';

import '../../domain/entities/formal_request_status.dart';

/// One-shot outcome the detail screen listens to (on each [eventVersion]
/// bump) for a snackbar + navigation side effect.
enum CaseStatusOutcome { none, success, failure }

class MatchmakerCaseStatusState extends Equatable {
  /// The target status currently being submitted, or `null` when idle.
  final FormalRequestStatus? inFlight;

  final CaseStatusOutcome outcome;
  final int eventVersion;

  /// On success: the server's result text (raw, already human-readable).
  /// On failure: a locale key (run through `.t`) — the local invalid-
  /// transition string, or the failure's own message.
  final String? message;

  /// True when the failure was an `INVALID_STATUS_TRANSITION` — the screen
  /// shows a local message and refreshes the list (the real status moved).
  final bool isInvalidTransition;

  const MatchmakerCaseStatusState({
    this.inFlight,
    this.outcome = CaseStatusOutcome.none,
    this.eventVersion = 0,
    this.message,
    this.isInvalidTransition = false,
  });

  bool get isBusy => inFlight != null;

  MatchmakerCaseStatusState copyWith({
    FormalRequestStatus? inFlight,
    bool clearInFlight = false,
    CaseStatusOutcome? outcome,
    int? eventVersion,
    String? message,
    bool clearMessage = false,
    bool? isInvalidTransition,
  }) {
    return MatchmakerCaseStatusState(
      inFlight: clearInFlight ? null : (inFlight ?? this.inFlight),
      outcome: outcome ?? this.outcome,
      eventVersion: eventVersion ?? this.eventVersion,
      message: clearMessage ? null : (message ?? this.message),
      isInvalidTransition: isInvalidTransition ?? this.isInvalidTransition,
    );
  }

  @override
  List<Object?> get props =>
      [inFlight, outcome, eventVersion, message, isInvalidTransition];
}
