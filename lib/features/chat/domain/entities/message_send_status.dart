/// Local-only status for an outgoing message bubble.
///
/// `sent` is implied for any message that originated from the server
/// (REST GET / SignalR ReceiveMessage); `sending` and `failed` only
/// apply to optimistic temps the cubit holds locally.
enum MessageSendStatus {
  sending,
  sent,
  failed,
}
