/// Status of a case's photo-exchange request (`photoExchange.status`).
/// Matchmaker-module-local — deliberately distinct from the likes-module
/// `PhotoExchangeStatus` so the modules stay decoupled. Unknown wire values
/// fall back to [unknown].
enum CasePhotoExchangeStatus {
  pending,
  accepted,
  rejected,
  expired,
  unknown;

  static CasePhotoExchangeStatus fromString(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'pending':
        return CasePhotoExchangeStatus.pending;
      case 'accepted':
        return CasePhotoExchangeStatus.accepted;
      case 'rejected':
        return CasePhotoExchangeStatus.rejected;
      case 'expired':
        return CasePhotoExchangeStatus.expired;
      default:
        return CasePhotoExchangeStatus.unknown;
    }
  }
}
