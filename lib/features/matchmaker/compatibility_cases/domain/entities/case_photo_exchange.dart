import 'package:equatable/equatable.dart';

import '../../../../../core/utils/server_clock.dart';
import 'case_photo_exchange_status.dart';

/// A case's photo-exchange request. [initiatorId] / [responderId] are
/// newly-added server fields (nullable, absent from older payloads); not
/// surfaced in the 3a list UI.
class CasePhotoExchange extends Equatable {
  final int requestId;
  final CasePhotoExchangeStatus status;
  final DateTime? respondedAt;

  /// Deadline for the two members to respond. Nullable on purpose: the field
  /// arrived with the same release as this countdown, so a payload cached
  /// before it — or served by an instance still rolling out — simply has none.
  /// That reads as "no deadline to show", never as a crash and never as an
  /// expiry.
  final DateTime? expiresAt;

  final String? initiatorId;
  final String? responderId;

  const CasePhotoExchange({
    required this.requestId,
    required this.status,
    required this.respondedAt,
    required this.initiatorId,
    required this.responderId,
    this.expiresAt,
  });

  /// Still genuinely open — status AND deadline, the same rule the likes rows
  /// use. The card shows its countdown only for this.
  bool get isAwaitingResponse =>
      status == CasePhotoExchangeStatus.pending && !hasServerExpired(expiresAt);

  @override
  List<Object?> get props => [
    requestId,
    status,
    respondedAt,
    expiresAt,
    initiatorId,
    responderId,
  ];
}
