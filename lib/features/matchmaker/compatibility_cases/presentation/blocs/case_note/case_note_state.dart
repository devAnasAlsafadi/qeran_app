import 'package:equatable/equatable.dart';

import '../../../domain/entities/case_note.dart';

/// The initial GET phase.
enum CaseNoteLoad { loading, ready, error }

/// Which mutation is currently running.
enum CaseNoteAction { save, delete }

/// One-shot side effect the sheet reacts to (on every [eventVersion] bump,
/// ignoring [none]).
enum CaseNoteOutcome { none, saveSuccess, deleteSuccess, failure }

/// Routes a [CaseNoteOutcome.failure] in the UI: inline vs toast vs pop.
enum CaseNoteErrorKind {
  none,
  validation,
  unauthorized,
  caseNotFound,
  notInvolved,
  generic,
}

class CaseNoteState extends Equatable {
  final CaseNoteLoad load;

  /// The loaded note, or `null` when none exists yet.
  final CaseNote? note;

  /// Error text for [CaseNoteLoad.error] (the initial GET).
  final String? loadErrorMessage;

  /// The mutation in flight, or `null` when idle.
  final CaseNoteAction? inFlight;

  final CaseNoteOutcome outcome;
  final CaseNoteErrorKind errorKind;

  /// Server message for a [CaseNoteErrorKind.generic] failure.
  final String? outcomeMessage;
  final int eventVersion;

  const CaseNoteState({
    this.load = CaseNoteLoad.loading,
    this.note,
    this.loadErrorMessage,
    this.inFlight,
    this.outcome = CaseNoteOutcome.none,
    this.errorKind = CaseNoteErrorKind.none,
    this.outcomeMessage,
    this.eventVersion = 0,
  });

  bool get isBusy => inFlight != null;
  bool get hasNote => note != null;

  CaseNoteState copyWith({
    CaseNoteLoad? load,
    CaseNote? note,
    bool clearNote = false,
    String? loadErrorMessage,
    bool clearLoadError = false,
    CaseNoteAction? inFlight,
    bool clearInFlight = false,
    CaseNoteOutcome? outcome,
    CaseNoteErrorKind? errorKind,
    String? outcomeMessage,
    bool clearOutcomeMessage = false,
    int? eventVersion,
  }) {
    return CaseNoteState(
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
