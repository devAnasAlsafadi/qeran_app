/// The notification kind from the wire `type` field (PascalCase on the wire:
/// `Match` / `Chat` / `Profile` / `Announcement` / `Offer` / `General` /
/// `Community`). Drives the leading icon-chip tone. Tolerant [unknown] for
/// any future value.
enum NotificationType {
  match,
  chat,
  profile,
  announcement,
  offer,
  general,

  /// The discussion under a post (contract §7.2): a reply to my comment, and
  /// — the matchmaker's — a new comment or a report on her post.
  community,
  unknown;

  static NotificationType fromWire(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'match':
        return NotificationType.match;
      case 'chat':
        return NotificationType.chat;
      case 'profile':
        return NotificationType.profile;
      case 'announcement':
        return NotificationType.announcement;
      case 'offer':
        return NotificationType.offer;
      case 'general':
        return NotificationType.general;
      case 'community':
        return NotificationType.community;
      default:
        return NotificationType.unknown;
    }
  }
}
