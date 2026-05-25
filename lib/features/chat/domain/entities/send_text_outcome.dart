import 'chat_message.dart';

/// Typed outcomes for `POST /api/chat/conversations/{id}/messages`.
/// Lives on the `Right` of `Either<Failure, SendTextOutcome>`;
/// transport / unmapped failures stay on the `Left` as `Failure`.
sealed class SendTextOutcome {
  const SendTextOutcome();
}

final class SendTextSuccess extends SendTextOutcome {
  final ChatMessage message;
  const SendTextSuccess({required this.message});
}

/// `VALIDATION_ERROR` — empty / whitespace / > 2000 chars. We
/// validate client-side so this should be rare.
final class SendTextValidationError extends SendTextOutcome {
  final String serverMessage;
  const SendTextValidationError({required this.serverMessage});
}

/// `CONVERSATION_NOT_FOUND` — id is wrong or conversation removed.
final class SendTextConversationNotFound extends SendTextOutcome {
  final String serverMessage;
  const SendTextConversationNotFound({required this.serverMessage});
}

/// `UNAUTHORIZED` — sender isn't a participant (shouldn't happen
/// in normal flow; defensive).
final class SendTextUnauthorized extends SendTextOutcome {
  final String serverMessage;
  const SendTextUnauthorized({required this.serverMessage});
}

/// HTTP 429 — 60/min cap exceeded. UI applies a short cooldown.
final class SendTextRateLimited extends SendTextOutcome {
  final String serverMessage;
  const SendTextRateLimited({required this.serverMessage});
}

final class SendTextFailure extends SendTextOutcome {
  final String serverMessage;
  final String? errorCode;
  const SendTextFailure({required this.serverMessage, required this.errorCode});
}
