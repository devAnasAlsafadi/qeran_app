/// The specific event inside an overloaded notification, read from the wire
/// `data.action` field. The `Match` type covers several distinct events
/// (a new like, a mutual accept, the photo-exchange steps, a formal
/// compatibility-case update) — [NotificationAction] disambiguates them so the
/// tile can pick the right icon. Tolerant [none] for absent/unknown actions.
enum NotificationAction {
  like,
  likeAccepted,
  photoExchangeRequested,
  photoExchangeAccepted,
  photoExchangeRejected,
  profileApproved,
  profileRejected,
  compatibilityCaseUpdated,
  none;

  static NotificationAction fromWire(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'like':
        return NotificationAction.like;
      case 'like_accepted':
        return NotificationAction.likeAccepted;
      case 'photo_exchange_requested':
        return NotificationAction.photoExchangeRequested;
      case 'photo_exchange_accepted':
        return NotificationAction.photoExchangeAccepted;
      case 'photo_exchange_rejected':
        return NotificationAction.photoExchangeRejected;
      case 'profile_approved':
        return NotificationAction.profileApproved;
      case 'profile_rejected':
        return NotificationAction.profileRejected;
      case 'compatibility_case_updated':
        return NotificationAction.compatibilityCaseUpdated;
      default:
        return NotificationAction.none;
    }
  }
}
