/// Who authored a chat message, from the wire `type` field (PascalCase on the
/// wire: `User` / `System`).
///
/// Only [system] messages carry the localized `contentAr` / `contentEn` pair;
/// a [user] message has just `content`. [unknown] covers a missing or future
/// value and deliberately behaves like [user] at the render site — see
/// [usesLocalizedContent]. Reading the type EXPLICITLY is the contract: the
/// kind is never inferred from an empty `contentEn`.
enum MessageType {
  user,
  system,
  unknown;

  static MessageType fromWire(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'user':
        return MessageType.user;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.unknown;
    }
  }

  /// Whether the localized pair should be consulted at all.
  ///
  /// Only an explicit [system] qualifies. An absent or unrecognised type falls
  /// through to the plain `content`, which the backend always populates — so a
  /// new server-side kind renders readable text instead of a blank bubble.
  bool get usesLocalizedContent => this == MessageType.system;
}
