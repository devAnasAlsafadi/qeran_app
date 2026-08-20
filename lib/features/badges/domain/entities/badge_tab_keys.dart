/// The wire names `GET /api/badges` keys its counts by, and the exact strings
/// `POST /api/badges/mark-seen` expects in `{ "tab": ... }`.
///
/// Constants rather than an enum on purpose. The contract is explicitly
/// open — the server may add keys, and an unrecognised one must be ignored in
/// silence — so an exhaustive Dart type would be a lie about the wire and a
/// crash risk the first time the backend grows. These exist to keep call sites
/// from hand-writing the strings, not to enumerate what the server may send.
class BadgeTabKeys {
  const BadgeTabKeys._();

  // ── Both roles ──
  static const String notifications = 'notificationsUnread';

  // ── User app ──
  static const String likes = 'likesUnread';
  static const String chat = 'chatUnread';

  /// Live since batch 18 — raised on profile approve/reject.
  static const String account = 'accountUnread';

  // ── Matchmaker app ──
  static const String users = 'usersUnread';
  static const String cases = 'casesUnread';
  static const String conversations = 'conversationsUnread';

  /// Documented by the backend as permanently zero for BOTH roles, and
  /// deliberately not rendered anywhere — a tab that can never light must not
  /// carry a badge. Named here only so the parser's intent is legible and
  /// nobody wires it by mistake.
  static const String explore = 'exploreUnread';

  /// Permanently zero, matchmaker side. Same reasoning as [explore].
  static const String dashboard = 'dashboardUnread';
}
