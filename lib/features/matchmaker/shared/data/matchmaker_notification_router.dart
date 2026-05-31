import 'json_parsers.dart';

/// A matchmaker deep-link intent parsed from an FCM `data` payload.
///
/// Sealed so the shell's `switch` is exhaustive. The parser is pure and
/// never-throws; ids arrive as strings on the wire and are coerced.
sealed class MatchmakerDeepLink {
  const MatchmakerDeepLink();
}

/// Open a user conversation (the 4b matchmaker chat). [senderName] comes
/// from the push so the header renders immediately (no blank header).
class OpenUserChat extends MatchmakerDeepLink {
  const OpenUserChat({required this.conversationId, required this.senderName});
  final int conversationId;
  final String senderName;
}

/// Open the Cases tab (M3). [highlightCaseId] is optional / nice-to-have.
class OpenCases extends MatchmakerDeepLink {
  const OpenCases({this.highlightCaseId});
  final int? highlightCaseId;
}

/// Not a matchmaker deep-link we handle → no-op.
class IgnoreDeepLink extends MatchmakerDeepLink {
  const IgnoreDeepLink();
}

/// Pure parser: FCM `data` (string-valued map) → a [MatchmakerDeepLink].
///
/// Guards (built to the real backend payloads):
///   • Cases: `action == "compatibility_case_updated"` AND
///     `audience == "matchmaker"`. The same event is also pushed to the
///     two USERS, so the explicit `audience` field is what keeps the
///     matchmaker shell from acting on a user-targeted push.
///   • Chat: `type == "chat"` with a parseable `conversationId`.
/// Anything else → [IgnoreDeepLink]. Never throws.
class MatchmakerNotificationRouter {
  const MatchmakerNotificationRouter._();

  static MatchmakerDeepLink parse(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return const IgnoreDeepLink();

    final type = parseString(data['type']).toLowerCase();
    final action = parseString(data['action']).toLowerCase();
    final audience = parseString(data['audience']).toLowerCase();

    if (action == 'compatibility_case_updated' && audience == 'matchmaker') {
      return OpenCases(highlightCaseId: parseNullableInt(data['caseId']));
    }

    if (type == 'chat') {
      final id = parseNullableInt(data['conversationId']);
      if (id == null) return const IgnoreDeepLink();
      return OpenUserChat(
        conversationId: id,
        senderName: parseString(data['senderName']),
      );
    }

    return const IgnoreDeepLink();
  }
}
