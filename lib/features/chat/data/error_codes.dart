/// Backend `errorCode` constants for the chat domain. Classifier in
/// `chat_remote_datasource.dart` switches on these first; raw Arabic
/// message matching is the fallback path.
class ChatErrorCodes {
  ChatErrorCodes._();

  // Send-message + share-profile
  static const String validationError = 'VALIDATION_ERROR';
  static const String conversationNotFound = 'CONVERSATION_NOT_FOUND';
  static const String unauthorized = 'UNAUTHORIZED';

  // Share-profile only
  static const String profileNotFound = 'PROFILE_NOT_FOUND';
}
