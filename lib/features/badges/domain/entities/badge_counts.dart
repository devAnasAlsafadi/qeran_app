import 'package:equatable/equatable.dart';

import 'badge_tab_keys.dart';

/// Unread counts for the signed-in role's tabs, keyed by the server's own
/// names.
///
/// The map is private and the readers are typed. Storing a map keeps the
/// contract's two rules free — an absent key reads as zero, an unrecognised
/// one is carried without ceremony and simply never asked for — while the
/// getters keep call sites from spelling a key wrong and silently rendering a
/// permanent zero.
class BadgeCounts extends Equatable {
  const BadgeCounts(this._counts);

  const BadgeCounts.empty() : _counts = const <String, int>{};

  final Map<String, int> _counts;

  /// Absent means zero — the server sends only what is non-zero.
  int of(String tabKey) => _counts[tabKey] ?? 0;

  bool has(String tabKey) => of(tabKey) > 0;

  // ── Both roles ──
  int get notifications => of(BadgeTabKeys.notifications);

  // ── User app ──
  int get likes => of(BadgeTabKeys.likes);
  int get chat => of(BadgeTabKeys.chat);
  int get account => of(BadgeTabKeys.account);

  // ── Matchmaker app ──
  int get users => of(BadgeTabKeys.users);
  int get cases => of(BadgeTabKeys.cases);
  int get conversations => of(BadgeTabKeys.conversations);

  /// Replaces one tab's count. Assignment, never addition: `BadgeUpdated`
  /// carries the absolute value, so adding would double-count every event
  /// that arrives after a REST refresh already included it.
  BadgeCounts withTab(String tabKey, int count) =>
      BadgeCounts({..._counts, tabKey: count});

  /// Locally zeroes one tab, for the optimistic half of mark-seen.
  BadgeCounts cleared(String tabKey) => withTab(tabKey, 0);

  @override
  List<Object?> get props => [_counts];

  @override
  String toString() => 'BadgeCounts($_counts)';
}
