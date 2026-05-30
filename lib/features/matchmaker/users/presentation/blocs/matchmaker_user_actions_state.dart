import 'package:equatable/equatable.dart';

/// Which review action is currently running.
enum MatchmakerUserAction { approve, reject, requestImage }

/// One-shot outcome the screen listens to for snackbar + navigation side
/// effects. The screen reacts on every [MatchmakerUserActionsState.eventVersion]
/// bump and ignores [none], so a toast never fires twice for one tap.
enum MatchmakerActionOutcome {
  none,
  approveSuccess,
  rejectSuccess,
  requestImageSuccess,
  failure,
}

class MatchmakerUserActionsState extends Equatable {
  /// The action currently in flight, or `null` when idle.
  final MatchmakerUserAction? inFlight;

  final MatchmakerActionOutcome outcome;
  final int eventVersion;

  /// Error text for a [MatchmakerActionOutcome.failure] (locale key or
  /// ready Arabic) — run through `.t(context)` in the UI.
  final String? errorMessage;

  const MatchmakerUserActionsState({
    this.inFlight,
    this.outcome = MatchmakerActionOutcome.none,
    this.eventVersion = 0,
    this.errorMessage,
  });

  bool get isBusy => inFlight != null;

  MatchmakerUserActionsState copyWith({
    MatchmakerUserAction? inFlight,
    bool clearInFlight = false,
    MatchmakerActionOutcome? outcome,
    int? eventVersion,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MatchmakerUserActionsState(
      inFlight: clearInFlight ? null : (inFlight ?? this.inFlight),
      outcome: outcome ?? this.outcome,
      eventVersion: eventVersion ?? this.eventVersion,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [inFlight, outcome, eventVersion, errorMessage];
}
