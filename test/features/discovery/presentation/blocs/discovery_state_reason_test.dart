import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_empty_reason.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_profile.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_state.dart';

DiscoveryProfile _profile(String id) => DiscoveryProfile(
  id: id,
  name: 'name-$id',
  age: 25,
  images: const [],
  matchingScore: 0,
  placements: const [],
);

/// [profileCount] cards, sitting at [currentIndex], on page [currentPage] of
/// [totalPages]. Everything the two derived signals read, and nothing else.
DiscoveryLoaded _state({
  int profileCount = 3,
  int currentIndex = 0,
  int currentPage = 1,
  int totalPages = 1,
  DiscoveryEmptyReason? reason,
}) => DiscoveryLoaded(
  profiles: List.generate(profileCount, (i) => _profile('p$i')),
  currentIndex: currentIndex,
  currentPage: currentPage,
  totalPages: totalPages,
  totalCount: profileCount,
  currentReason: reason,
);

/// The deck's terminal state has two INDEPENDENT sources, and the CTAs branch
/// on them separately:
///
/// * the server naming a reason — the only thing it can know, and only for a
///   response that carried nobody, and
/// * the client watching the user swipe past the last card — which the server
///   never hears about.
///
/// These pin that neither collapses into the other, and that both can be true
/// at once.
void main() {
  group('sawEveryLoadedProfile (client inference)', () {
    test('true once the last loaded card is swiped past and no page remains', () {
      final s = _state(profileCount: 3, currentIndex: 3);

      expect(s.sawEveryLoadedProfile, isTrue);
    });

    // THE guard. `isExhausted` is `currentIndex >= profiles.length`, which is
    // ALSO true of a deck that never had anything (0 >= 0). Without the
    // `profiles.isNotEmpty` half, "you have seen everyone" fires at a user who
    // was shown nobody. Do not simplify this away.
    test('false for a deck that never had profiles (0 >= 0 is not exhaustion)', () {
      final s = _state(profileCount: 0, currentIndex: 0);

      expect(s.isExhausted, isTrue, reason: 'the 0 >= 0 trap this guards');
      expect(s.sawEveryLoadedProfile, isFalse);
    });

    test('false while a card is still showing', () {
      final s = _state(profileCount: 3, currentIndex: 1);

      expect(s.sawEveryLoadedProfile, isFalse);
    });

    test('false while another page is still fetchable', () {
      final s = _state(profileCount: 3, currentIndex: 3, totalPages: 2);

      expect(s.hasMore, isTrue);
      expect(s.sawEveryLoadedProfile, isFalse);
    });
  });

  group('hasSeenEveryone (union of both signals)', () {
    test('fires on the client inference alone, with no server reason', () {
      final s = _state(profileCount: 3, currentIndex: 3);

      expect(s.currentReason, isNull);
      expect(s.hasSeenEveryone, isTrue);
    });

    test('fires on the server reason alone, on a page that carried nobody', () {
      final s = _state(profileCount: 0, reason: DiscoveryEmptyReason.seenAll);

      expect(s.sawEveryLoadedProfile, isFalse);
      expect(s.hasSeenEveryone, isTrue);
    });

    test('stays false when neither signal is present', () {
      final s = _state(profileCount: 3, currentIndex: 1);

      expect(s.hasSeenEveryone, isFalse);
    });

    test('a reason this build cannot read does not fire it', () {
      final s = _state(profileCount: 0, reason: DiscoveryEmptyReason.unknown);

      expect(s.hasSeenEveryone, isFalse);
      expect(s.filtersMatchedNobody, isFalse);
    });
  });

  group('filtersMatchedNobody', () {
    test('fires only on the filters reason', () {
      final s = _state(
        profileCount: 0,
        reason: DiscoveryEmptyReason.noMatchesForFilters,
      );

      expect(s.filtersMatchedNobody, isTrue);
      expect(s.hasSeenEveryone, isFalse);
    });

    test('the exhausted-deck inference does not imply it', () {
      final s = _state(profileCount: 3, currentIndex: 3);

      expect(s.filtersMatchedNobody, isFalse);
    });
  });

  // The overlap the CTA rule exists for: the filter matched nobody NEW, and the
  // user had already swiped through everyone it did match. Both remedies are
  // legitimate, so both signals must survive independently rather than one
  // shadowing the other.
  test('both signals can be true at once', () {
    final s = _state(
      profileCount: 3,
      currentIndex: 3,
      reason: DiscoveryEmptyReason.noMatchesForFilters,
    );

    expect(s.hasSeenEveryone, isTrue);
    expect(s.filtersMatchedNobody, isTrue);
  });

  group('copyWith', () {
    test('carries the reason through an unrelated copy', () {
      final s = _state(reason: DiscoveryEmptyReason.seenAll);

      expect(s.copyWith(currentIndex: 1).currentReason,
          DiscoveryEmptyReason.seenAll);
    });

    test('resetReason clears it — the whole point of the flag', () {
      final s = _state(reason: DiscoveryEmptyReason.seenAll);

      expect(s.copyWith(resetReason: true).currentReason, isNull);
    });

    // Same precedence as resetActionError / resetPrefetchError: the reset flag
    // wins. The prefetch path passes both at once (`currentReason: page.reason,
    // resetReason: page.reason == null`), so this ordering is what makes a
    // reason-less page actually clear the previous one.
    test('resetReason beats an explicitly passed reason', () {
      final s = _state(reason: DiscoveryEmptyReason.seenAll);

      final next = s.copyWith(
        currentReason: DiscoveryEmptyReason.noMatchesForFilters,
        resetReason: true,
      );

      expect(next.currentReason, isNull);
    });

    test('setting a reason replaces the previous one', () {
      final s = _state(reason: DiscoveryEmptyReason.seenAll);

      final next =
          s.copyWith(currentReason: DiscoveryEmptyReason.noMatchesForFilters);

      expect(next.currentReason, DiscoveryEmptyReason.noMatchesForFilters);
    });
  });

  // In `props`, so a reason arriving on an otherwise identical state still
  // rebuilds the empty view instead of being deduped away by Equatable.
  test('states differing only in reason are not equal', () {
    expect(
      _state(reason: DiscoveryEmptyReason.seenAll),
      isNot(equals(_state())),
    );
  });
}
