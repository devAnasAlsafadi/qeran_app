/// Direction of a pending photo-exchange request from the current
/// user's perspective. `Sent` = I initiated, `Received` = they did.
enum PhotoExchangeDirection {
  sent,
  received,
  unknown;

  static PhotoExchangeDirection fromString(Object? raw) {
    if (raw is! String) return PhotoExchangeDirection.unknown;
    switch (raw) {
      case 'Sent':
        return PhotoExchangeDirection.sent;
      case 'Received':
        return PhotoExchangeDirection.received;
    }
    return PhotoExchangeDirection.unknown;
  }
}
