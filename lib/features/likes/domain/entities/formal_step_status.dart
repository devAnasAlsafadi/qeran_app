/// Status of a formal-step request (`pendingFormalStep.status`).
///
/// ⚠️ Parsed from a bare STRING. Unlike `pendingPhotoExchange`, this block
/// carries no numeric `statusCode` at all, so there is no code path to fall
/// back on — a spelling the client does not know becomes [unknown] and the
/// row reads as "not awaiting a response".
///
/// ⚠️ Only `Pending` is confirmed against a real payload. The other three are
/// inferred from the photo-exchange vocabulary, which the formal step mirrors
/// everywhere else. They matter only once the receiver card exists; until then
/// nothing branches on them. If one turns out to be spelled differently,
/// [unknown] absorbs it rather than mis-reporting a live request.
enum FormalStepStatus {
  pending,
  accepted,
  rejected,
  expired,
  unknown;

  static FormalStepStatus fromString(Object? raw) {
    if (raw is! String) return FormalStepStatus.unknown;
    switch (raw.toLowerCase()) {
      case 'pending':
        return FormalStepStatus.pending;
      case 'accepted':
        return FormalStepStatus.accepted;
      case 'rejected':
        return FormalStepStatus.rejected;
      case 'expired':
        return FormalStepStatus.expired;
      default:
        return FormalStepStatus.unknown;
    }
  }
}
