import 'package:equatable/equatable.dart';

enum AnswerSaveOutcome { none, success, failure }

enum AnswerSaveErrorKind { none, unauthorized, generic }

/// Save state for the editable-answers screen. Tracks which row's save is
/// in flight, plus a one-shot outcome (consumed on [eventVersion] bumps)
/// the screen turns into a snackbar + an in-place list update.
class MatchmakerAnswerSaveState extends Equatable {
  /// The questionId whose save is in flight, or `null` when idle.
  final int? inFlightQuestionId;

  final AnswerSaveOutcome outcome;
  final int eventVersion;

  /// The question the latest event refers to + the text that was saved
  /// (used to update the row in place on success).
  final int? lastQuestionId;
  final String? lastAnswer;

  /// Error text for a [AnswerSaveOutcome.failure] (locale key or ready
  /// Arabic) — run through `.t(context)` in the UI.
  final String? errorMessage;
  final AnswerSaveErrorKind errorKind;

  const MatchmakerAnswerSaveState({
    this.inFlightQuestionId,
    this.outcome = AnswerSaveOutcome.none,
    this.eventVersion = 0,
    this.lastQuestionId,
    this.lastAnswer,
    this.errorMessage,
    this.errorKind = AnswerSaveErrorKind.none,
  });

  bool isSaving(int questionId) => inFlightQuestionId == questionId;

  MatchmakerAnswerSaveState copyWith({
    int? inFlightQuestionId,
    bool clearInFlight = false,
    AnswerSaveOutcome? outcome,
    int? eventVersion,
    int? lastQuestionId,
    String? lastAnswer,
    String? errorMessage,
    bool clearError = false,
    AnswerSaveErrorKind? errorKind,
  }) {
    return MatchmakerAnswerSaveState(
      inFlightQuestionId: clearInFlight
          ? null
          : (inFlightQuestionId ?? this.inFlightQuestionId),
      outcome: outcome ?? this.outcome,
      eventVersion: eventVersion ?? this.eventVersion,
      lastQuestionId: lastQuestionId ?? this.lastQuestionId,
      lastAnswer: lastAnswer ?? this.lastAnswer,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorKind: errorKind ?? this.errorKind,
    );
  }

  @override
  List<Object?> get props => [
    inFlightQuestionId,
    outcome,
    eventVersion,
    lastQuestionId,
    lastAnswer,
    errorMessage,
    errorKind,
  ];
}
