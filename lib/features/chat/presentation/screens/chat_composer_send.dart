import '../blocs/conversation_cubit.dart';
import '../blocs/conversation_state.dart';

/// Sends [raw] from the composer and reports whether it left for good.
///
/// False only when this send was rate limited — by the local cooldown or by
/// the server — which never sends it, so the composer gives the text back.
/// Read from the state the send itself published: the event version moves on
/// every event, so an earlier rate limit can't be mistaken for this one.
Future<bool> sendFromComposer(ConversationCubit cubit, String raw) async {
  final before = cubit.state.eventVersion;
  await cubit.sendText(raw);
  final after = cubit.state;
  final rateLimited =
      after.eventVersion != before &&
      after.event == ConversationEvent.sendRateLimited;
  return !rateLimited;
}
