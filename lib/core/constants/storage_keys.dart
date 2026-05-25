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
}
