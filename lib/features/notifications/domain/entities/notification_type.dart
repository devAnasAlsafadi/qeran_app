/// The notification kind from the wire `type` field (PascalCase on the wire:
/// `Match` / `Chat` / `Profile` / `Announcement` / `Offer` / `General`). Drives
/// the leading icon-chip tone. Tolerant [unknown] for any future value.
enum NotificationType {
  match,
  chat,
  profile,
  announcement,
  offer,
  general,
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
      default:
        return NotificationType.unknown;
    }
  }
}
