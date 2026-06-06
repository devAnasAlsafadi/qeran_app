import 'package:equatable/equatable.dart';

import '../../domain/entities/matchmaker_user_note.dart';

/// The initial GET phase.
enum MatchmakerNotesLoad { loading, ready, error }

/// Which mutation is currently running.
enum MatchmakerNotesAction { save, delete }

/// One-shot side effect the sheet reacts to (on every [eventVersion] bump,
/// ignoring [none]).
enum MatchmakerNotesOutcome { none, saveSuccess, deleteSuccess, failure }

/// Routes a [MatchmakerNotesOutcome.failure] in the UI: inline vs toast vs pop.
enum MatchmakerNotesErrorKind {
  none,
  validation,
  unauthorized,
  userNotFound,
  generic,
}

class MatchmakerUserNotesState extends Equatable {
  final MatchmakerNotesLoad load;

  /// The loaded note, or `null` when none exists yet.
  final MatchmakerUserNote? note;

  /// Error text for [MatchmakerNotesLoad.error] (the initial GET).
  final String? loadErrorMessage;

  /// The mutation in flight, or `null` when idle.
  final MatchmakerNotesAction? inFlight;

  final MatchmakerNotesOutcome outcome;
  final MatchmakerNotesErrorKind errorKind;

  /// Server message for a [MatchmakerNotesErrorKind.generic] failure.
  final String? outcomeMessage;
  final int eventVersion;

  const MatchmakerUserNotesState({
    this.load = MatchmakerNotesLoad.loading,
    this.note,
    this.loadErrorMessage,
    this.inFlight,
    this.outcome = MatchmakerNotesOutcome.none,
    this.errorKind = MatchmakerNotesErrorKind.none,
    this.outcomeMessage,
    this.eventVersion = 0,
  });

  bool get isBusy => inFlight != null;
  bool get hasNote => note != null;

  MatchmakerUserNotesState copyWith({
    MatchmakerNotesLoad? load,
    MatchmakerUserNote? note,
    bool clearNote = false,
    String? loadErrorMessage,
    bool clearLoadError = false,
    MatchmakerNotesAction? inFlight,
    bool clearInFlight = false,
    MatchmakerNotesOutcome? outcome,
    MatchmakerNotesErrorKind? errorKind,
    String? outcomeMessage,
    bool clearOutcomeMessage = false,
    int? eventVersion,
  }) {
    return MatchmakerUserNotesState(
      load: load ?? this.load,
      note: clearNote ? null : (note ?? this.note),
      loadErrorMessage:
          clearLoadError ? null : (loadErrorMessage ?? this.loadErrorMessage),
      inFlight: clearInFlight ? null : (inFlight ?? this.inFlight),
      outcome: outcome ?? this.outcome,
      errorKind: errorKind ?? this.errorKind,
      outcomeMessage:
          clearOutcomeMessage ? null : (outcomeMessage ?? this.outcomeMessage),
      eventVersion: eventVersion ?? this.eventVersion,
    );
  }

  @override
  List<Object?> get props => [
        load,
        note,
        loadErrorMessage,
        inFlight,
        outcome,
        errorKind,
        outcomeMessage,
        eventVersion,
      ];
}
