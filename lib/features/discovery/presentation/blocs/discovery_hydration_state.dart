import 'package:equatable/equatable.dart';
import 'package:qeran/features/profile/domain/entities/other_profile.dart';

/// Per-profile cache of the by-id hydration behind the merged discovery
/// screen's below-the-fold sections.
///
/// Keyed by profile id so undo — which walks BACK to a card already seen —
/// never refetches, and so a fast swipe through the deck doesn't discard work
/// that is about to be needed again.
class DiscoveryHydrationState extends Equatable {
  const DiscoveryHydrationState({
    this.byId = const {},
    this.failed = const {},
  });

  /// Successfully hydrated profiles.
  final Map<String, OtherProfile> byId;

  /// Ids whose hydrate failed. Kept so the body can fall back to the deck
  /// payload permanently instead of retrying on every rebuild — a failed
  /// hydrate must never block or repeat.
  final Set<String> failed;

  /// The full profile for [id], or null while it is still loading (or after
  /// it failed — the caller degrades to the seed either way).
  OtherProfile? profileFor(String id) => byId[id];

  /// True while [id] has neither landed nor failed, i.e. show the skeleton.
  bool isLoading(String id) => !byId.containsKey(id) && !failed.contains(id);

  DiscoveryHydrationState copyWith({
    Map<String, OtherProfile>? byId,
    Set<String>? failed,
  }) => DiscoveryHydrationState(
    byId: byId ?? this.byId,
    failed: failed ?? this.failed,
  );

  @override
  List<Object?> get props => [byId, failed];
}
