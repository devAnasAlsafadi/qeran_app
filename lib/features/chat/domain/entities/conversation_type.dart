/// Conversation type from the server. Today the only meaningful value
/// is `userToMatchmaker`; `unknown` is reserved for forward-compat
/// (admin / group / etc) so an unrecognised server value never crashes
/// the UI.
enum ConversationType {
  userToMatchmaker,
  unknown;

  static ConversationType fromString(Object? raw) {
    if (raw is! String) return ConversationType.unknown;
    switch (raw) {
      case 'UserToMatchmaker':
        return ConversationType.userToMatchmaker;
    }
    return ConversationType.unknown;
  }
}
