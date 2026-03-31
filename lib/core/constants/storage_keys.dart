class StorageKeys {
  static const String token = 'token';
  static const String firebaseUid = 'firebase_uid';
  static const String seenOnboarding = 'seen_onboarding';
  static const String isWhatsappVerified = 'is_whatsapp_verified';
  static const String finishedQuestions = 'finished_questions';
  static const String gender = 'gender';
  static const String signedOath = 'signed_oath';
  static const String userRole = 'user_role';

  /// Temporary userId persisted during the multi-step auth flow
  /// (register/login → add-phone → verify-otp). Cleared on OTP success.
  static const String pendingUserId = 'pending_user_id';
}

