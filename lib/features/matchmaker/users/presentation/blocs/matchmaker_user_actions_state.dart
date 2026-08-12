import 'package:equatable/equatable.dart';

/// Which review action is currently running.
enum MatchmakerUserAction { approve, reject, requestImage, approveImage }

/// One-shot outcome the screen listens to for snackbar + navigation side
/// effects. The screen reacts on every [MatchmakerUserActionsState.eventVersion]
/// bump and ignores [none], so a toast never fires twice for one tap.
enum MatchmakerActionOutcome {
  none,
  approveSuccess,
  rejectSuccess,
  requestImageSuccess,
  approveImageSuccess,
  failure,
}

enum MatchmakerActionErrorKind { none, unauthorized, generic }

class MatchmakerUserActionsState extends Equatable {
  /// The action currently in flight, or `null` when idle.
  final MatchmakerUserAction? inFlight;
  final String? inFlightImageId;

  final MatchmakerActionOutcome outcome;
  final int eventVersion;

  /// Error text for a [MatchmakerActionOutcome.failure] (locale key or
  /// ready Arabic) — run through `.t(context)` in the UI.
  final String? errorMessage;
  final MatchmakerActionErrorKind errorKind;

  const MatchmakerUserActionsState({
    this.inFlight,
    this.inFlightImageId,
    this.outcome = MatchmakerActionOutcome.none,
    this.eventVersion = 0,
    this.errorMessage,
    this.errorKind = MatchmakerActionErrorKind.none,
  });

  bool get isBusy => inFlight != null;

  MatchmakerUserActionsState copyWith({
    MatchmakerUserAction? inFlight,
    String? inFlightImageId,
    bool clearInFlight = false,
    MatchmakerActionOutcome? outcome,
    int? eventVersion,
    String? errorMessage,
    bool clearError = false,
    MatchmakerActionErrorKind? errorKind,
  }) {
    return MatchmakerUserActionsState(
      inFlight: clearInFlight ? null : (inFlight ?? this.inFlight),
      inFlightImageId: clearInFlight
          ? null
          : (inFlightImageId ?? this.inFlightImageId),
      outcome: outcome ?? this.outcome,
      eventVersion: eventVersion ?? this.eventVersion,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorKind: errorKind ?? this.errorKind,
    );
  }

  @override
  List<Object?> get props => [
    inFlight,
    inFlightImageId,
    outcome,
    eventVersion,
    errorMessage,
    errorKind,
  ];
}
