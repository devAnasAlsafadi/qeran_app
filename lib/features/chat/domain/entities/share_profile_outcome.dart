import 'chat_message.dart';

/// Typed outcomes for `POST /api/chat/conversations/{id}/share-profile`.
sealed class ShareProfileOutcome {
  const ShareProfileOutcome();
}

final class ShareProfileSuccess extends ShareProfileOutcome {
  final ChatMessage message;
  const ShareProfileSuccess({required this.message});
}

/// `PROFILE_NOT_FOUND` — sharedUserId doesn't resolve to a profile.
final class ShareProfileNotFound extends ShareProfileOutcome {
  final String serverMessage;
  const ShareProfileNotFound({required this.serverMessage});
}

/// `VALIDATION_ERROR` — sharedUserId null/empty.
final class ShareProfileValidationError extends ShareProfileOutcome {
  final String serverMessage;
  const ShareProfileValidationError({required this.serverMessage});
}

final class ShareProfileConversationNotFound extends ShareProfileOutcome {
  final String serverMessage;
  const ShareProfileConversationNotFound({required this.serverMessage});
}

final class ShareProfileUnauthorized extends ShareProfileOutcome {
  final String serverMessage;
  const ShareProfileUnauthorized({required this.serverMessage});
}

/// HTTP 429 — 20/5min cap exceeded.
final class ShareProfileRateLimited extends ShareProfileOutcome {
  final String serverMessage;
  const ShareProfileRateLimited({required this.serverMessage});
}

final class ShareProfileFailure extends ShareProfileOutcome {
  final String serverMessage;
  final String? errorCode;
  const ShareProfileFailure({
    required this.serverMessage,
    required this.errorCode,
  });
}
