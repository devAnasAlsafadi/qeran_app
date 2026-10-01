/// The dev-flag states (Q2): `--dart-define=COMMUNITY_MOCK=seeded|empty|
/// errors|slow`, read only by Community's DI and only outside release
/// builds. [seeded] is the board's data; [empty] has no posts; [errors]
/// fails every call; [slow] answers after 3 s, so loaders stay visible.
enum CommunityMockMode {
  seeded,
  empty,
  errors,
  slow;

  /// Null for an empty or unknown flag — the live API is used then.
  static CommunityMockMode? fromFlag(String flag) {
    final name = flag.trim().toLowerCase();
    for (final mode in values) {
      if (mode.name == name) return mode;
    }
    return null;
  }
}
