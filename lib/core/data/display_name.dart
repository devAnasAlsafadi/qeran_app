/// Resolves the name shown for a user, whatever key the endpoint ships.
///
/// The backend migrated user names to `displayName`, but the endpoints did
/// not all land at once and an older build must keep rendering names, so the
/// new key wins and the legacy ones stay as fallbacks. Once every payload
/// carries `displayName` the tail of this list can be deleted without
/// touching a single render site.
///
/// `realName` is deliberately NOT consulted. It is collected for formal
/// proceedings, is never shown to another user, and must not leak into a
/// card, chat header or notification by way of a fallback.
///
/// [prefer] inserts endpoint-specific keys directly after `displayName` —
/// the interest payloads, for example, carry both `otherUserName` (the peer)
/// and `name`, and picking the wrong one would show the wrong person.
String parseDisplayName(
  Map<String, dynamic> json, {
  List<String> prefer = const [],
}) {
  for (final key in [
    'displayName',
    ...prefer,
    'name',
    'fullName',
    'firstName',
  ]) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return '';
}

/// The placeholder the backend backfilled onto users who never had a name.
/// Anyone still carrying it is prompted (once) to set a real one.
const String kDefaultDisplayName = 'مستخدم';
