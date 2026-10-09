/// ⚠️ When adding an ACCOUNT-level key here, also add it to [accountKeys]
/// (what sign-out and a permanent delete remove, at the bottom).
/// DEVICE-level keys (FCM registration markers, onboarding, OS-permission,
/// and easy_localization's locale) are intentionally PRESERVED across both.
class StorageKeys {
  static const String token = 'token';
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String firebaseUid = 'firebase_uid';
  static const String seenOnboarding = 'seen_onboarding';
  static const String isWhatsappVerified = 'is_whatsapp_verified';
  static const String finishedQuestions = 'finished_questions';
  static const String gender = 'gender';
  static const String signedOath = 'signed_oath';
  static const String userRole = 'user_role';
  static const String questionnaireDraft = 'questionnaire_draft';
  static const String uploadedPhotos = 'uploaded_photos';

  /// Temporary userId persisted during the multi-step auth flow
  /// (register/login → add-phone → verify-otp). Cleared on OTP success.
  static const String pendingUserId = 'pending_user_id';

  // ─── FCM / Devices ───────────────────────────────────
  static const String latestFcmToken = 'latest_fcm_token';
  static const String deviceRegistered = 'device_registered';
  static const String lastRegisteredFcm = 'last_registered_fcm';
  static const String lastRegisteredLang = 'last_registered_lang';
  static const String lastLinkedFcm = 'last_linked_fcm';
  static const String notifPermissionAsked = 'notif_permission_asked';

  /// A sign-out couldn't finish releasing this phone's push (offline): FCM
  /// still holds the old token, so the previous account's pushes can arrive.
  /// Retried at the next start and when the connection returns; cleared once
  /// FCM deletes the token or a sign-in links the phone (C2). DEVICE-level:
  /// it must outlive the account, so it is not in [accountKeys].
  static const String pushReleaseOwed = 'push_release_owed';

  /// Local READ watermark for the USER-app inbox — everything with an id at or
  /// below it counts as read. Set by "mark all as read".
  ///
  /// Deliberately SEPARATE from the bell: "seen" is the server's unread count,
  /// cleared by visiting the inbox; "read" is what greys a row out (you opened
  /// that notification, or cleared the lot). Still a local heuristic — the
  /// backend exposes no per-row read-state.
  static const String notifReadWatermark = 'notif_read_watermark';

  /// Ids read one by one, ABOVE [notifReadWatermark]. Stored as strings because
  /// SharedPreferences has no int list. Emptied whenever the watermark
  /// advances past them, so it stays small.
  static const String notifReadIds = 'notif_read_ids';

  /// Local READ watermark for the MATCHMAKER inbox — same idea as
  /// [notifReadWatermark], advanced to the newest loaded id on the way out of
  /// the inbox. There is no per-id list beside it: the matchmaker inbox has no
  /// "mark this one read" (no backend endpoint for it), so the watermark is the
  /// whole story.
  ///
  /// Kept SEPARATE from the user-app key — the two roles read the same
  /// endpoint but never share local state.
  static const String matchmakerNotifReadWatermark =
      'matchmaker_notif_read_watermark';

  /// Last known offset between the server's clock and this device's, in
  /// milliseconds. Read at bootstrap so the first countdown of a cold start
  /// is not judged by a device clock that may have drifted; overwritten by
  /// the first response that can recalibrate. Survives logout deliberately —
  /// it describes the DEVICE, not the account.
  static const String serverClockSkewMs = 'server_clock_skew_ms';

  /// Account/session shared-prefs keys, removed on sign-out and on a permanent
  /// delete so the next account on this phone inherits none of them. Device-
  /// level keys are intentionally absent here (preserved across both).
  static const List<String> accountKeys = [
    // Session / identity
    userId,
    userName,
    userEmail,
    userRole,
    firebaseUid,
    // Account state / profile
    isWhatsappVerified,
    finishedQuestions,
    gender,
    signedOath,
    questionnaireDraft,
    uploadedPhotos,
    pendingUserId,
    // Notification read-state heuristics (account-level)
    notifReadWatermark,
    notifReadIds,
    // Was missed when the matchmaker read watermark was added: without it the
    // next matchmaker to sign in on this device inherits the previous one's
    // read rows.
    matchmakerNotifReadWatermark,
    // Account-LINK marker only — the device REGISTRATION markers are preserved
    // so the next login re-links cleanly without a redundant re-register.
    lastLinkedFcm,
  ];
}
