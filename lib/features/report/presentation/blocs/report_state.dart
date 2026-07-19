import 'package:equatable/equatable.dart';

/// One-shot outcome of a report submission. [eventVersion] increments on every
/// terminal emit so a `BlocListener` fires once per attempt (mirrors the
/// delete-account cubit pattern).
enum ReportOutcome { none, success, failure }

class ReportState extends Equatable {
  final bool submitting;
  final ReportOutcome outcome;
  final int eventVersion;

  /// Localized key for the outcome snackbar (success or a classified failure).
  final String? messageKey;

  const ReportState({
    this.submitting = false,
    this.outcome = ReportOutcome.none,
    this.eventVersion = 0,
    this.messageKey,
  });

  ReportState copyWith({
    bool? submitting,
    ReportOutcome? outcome,
    int? eventVersion,
    String? messageKey,
  }) {
    return ReportState(
      submitting: submitting ?? this.submitting,
      outcome: outcome ?? this.outcome,
      eventVersion: eventVersion ?? this.eventVersion,
      messageKey: messageKey ?? this.messageKey,
    );
  }

  @override
  List<Object?> get props => [submitting, outcome, eventVersion, messageKey];
}
