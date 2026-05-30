import 'package:equatable/equatable.dart';

/// Neutral value object for the `CompatibilityCaseUpdated` SignalR event.
///
/// Real wire shape (camelCase), per the backend:
/// `{ caseId, formalRequestId, newStatus, newStatusCode, updatedAt }`.
///
/// [newStatus] is the `FormalRequestStatus` name (string — the source of
/// truth, mapped via `FormalRequestStatus.fromString`). [newStatusCode]
/// is its int (1..5), carried for logging/parity only. [updatedAt] is
/// ISO-8601 UTC.
class CompatibilityCaseUpdate extends Equatable {
  final int caseId;
  final int formalRequestId;
  final String newStatus;
  final int newStatusCode;
  final DateTime? updatedAt;

  const CompatibilityCaseUpdate({
    required this.caseId,
    required this.formalRequestId,
    required this.newStatus,
    required this.newStatusCode,
    required this.updatedAt,
  });

  @override
  List<Object?> get props =>
      [caseId, formalRequestId, newStatus, newStatusCode, updatedAt];
}
