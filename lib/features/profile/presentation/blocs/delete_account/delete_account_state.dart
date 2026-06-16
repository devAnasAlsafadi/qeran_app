import 'package:equatable/equatable.dart';

/// One-shot outcome the UI listens to — react on [DeleteAccountState.eventVersion]
/// change, ignore [none]. [success] → the account is gone AND local data wiped;
/// [failure] → the delete call failed and nothing was touched locally.
enum DeleteAccountOutcome { none, success, failure }

class DeleteAccountState extends Equatable {
  /// In-flight guard + drives the sheet's delete-button loader. Stays true
  /// across the whole sequence (delete → unlink → wipe) until the outcome.
  final bool deleting;

  final DeleteAccountOutcome outcome;
  final int eventVersion;

  /// Raw failure message (server text / locale key) — kept for logging; the UI
  /// shows a fixed friendly message regardless.
  final String? errorKey;

  const DeleteAccountState({
    this.deleting = false,
    this.outcome = DeleteAccountOutcome.none,
    this.eventVersion = 0,
    this.errorKey,
  });

  DeleteAccountState copyWith({bool? deleting, bool clearError = false}) {
    return DeleteAccountState(
      deleting: deleting ?? this.deleting,
      outcome: outcome,
      eventVersion: eventVersion,
      errorKey: clearError ? null : errorKey,
    );
  }

  @override
  List<Object?> get props => [deleting, outcome, eventVersion, errorKey];
}
