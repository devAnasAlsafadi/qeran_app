import 'package:equatable/equatable.dart';

import 'case_photo_exchange_status.dart';

/// A case's photo-exchange request. [initiatorId] / [responderId] are
/// newly-added server fields (nullable, absent from older payloads); not
/// surfaced in the 3a list UI.
class CasePhotoExchange extends Equatable {
  final int requestId;
  final CasePhotoExchangeStatus status;
  final DateTime? respondedAt;
  final String? initiatorId;
  final String? responderId;

  const CasePhotoExchange({
    required this.requestId,
    required this.status,
    required this.respondedAt,
    required this.initiatorId,
    required this.responderId,
  });

  @override
  List<Object?> get props =>
      [requestId, status, respondedAt, initiatorId, responderId];
}
