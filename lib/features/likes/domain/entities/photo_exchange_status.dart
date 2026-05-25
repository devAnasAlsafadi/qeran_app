/// Status of a photo-exchange request from the server.
///
/// `pendingPhotoExchange` only ever appears in `Pending` per backend
/// — the other states are reflected through the match `stage`. The
/// remaining values are parsed defensively for diagnostics.
enum PhotoExchangeStatus {
  pending,
  accepted,
  rejected,
  expired,
  unknown;

  static PhotoExchangeStatus fromCode(Object? raw) {
    final code = switch (raw) {
      int n => n,
      String s => int.tryParse(s),
      _ => null,
    };
    return switch (code) {
      0 => PhotoExchangeStatus.pending,
      1 => PhotoExchangeStatus.accepted,
      2 => PhotoExchangeStatus.rejected,
      3 => PhotoExchangeStatus.expired,
      _ => PhotoExchangeStatus.unknown,
    };
  }
}
