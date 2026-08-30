/// The specific event inside an overloaded notification, read from the wire
/// `data.action` field. The `Match` type covers several distinct events
/// (a new like, a mutual accept, the photo-exchange steps, the formal step and
/// the ways a case can end) — [NotificationAction] disambiguates them so the
/// tile can pick the right icon. Tolerant [none] for absent/unknown actions.
///
/// The V2 members were held back until the backend gave their wire strings
/// verbatim, rather than spelled from a paraphrase — the fallback glyph was
/// made neutral in the meantime so an unrecognised event never drew as a like.
/// They are the server's own values, confirmed 2026-08-29.
///
/// ⚠️ THREE endings, three names, and they are not interchangeable:
///   • [caseEnded] — the receiver DECLINED the formal step. Only that.
///   • [caseCancelled] — somebody called the case off, member or matchmaker.
///   • [compatibilityCaseUpdated] — the matchmaker recorded an outcome,
///     «لم ينجح» or «اكتمل بنجاح» alike.
///
/// The third carries `data.newStatus`, a PascalCase STRING
/// (`"CompatibilityClosed"` = «لم ينجح»). A `newStatusCode` int rides beside
/// it and must not be read: `caseStage` codes are 0-based and formal-request
/// codes are 1-based, both on this same payload, so `4` names two different
/// things depending on which scale the reader assumes. Nothing reads either
/// field yet — telling the two outcomes apart on the tile is a separate
/// decision, since the parser for that status lives in the likes module.
enum NotificationAction {
  like,
  likeAccepted,
  photoExchangeRequested,
  photoExchangeAccepted,
  photoExchangeRejected,

  /// The formal step was asked for. Reaches the RESPONDER only — the
  /// initiator already knows they sent it.
  formalStepRequested,

  /// The formal step was approved. Reaches the INITIATOR and the matchmaker;
  /// the receiver performed the action and is told nothing. The matchmaker's
  /// copy is the one carrying `audience: "matchmaker"`.
  formalStepAccepted,

  /// The receiver DECLINED the formal step — and nothing else. A cancelled
  /// case is [caseCancelled] and a recorded outcome is
  /// [compatibilityCaseUpdated].
  caseEnded,

  /// The case was called off, by a member or the matchmaker.
  caseCancelled,

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
      case 'formal_step_requested':
        return NotificationAction.formalStepRequested;
      case 'formal_step_accepted':
        return NotificationAction.formalStepAccepted;
      case 'case_ended':
        return NotificationAction.caseEnded;
      case 'case_cancelled':
        return NotificationAction.caseCancelled;
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
