import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/features/badges/domain/entities/badge_tab_keys.dart';
import 'package:qeran/features/badges/domain/usecases/get_badges_usecase.dart';
import 'package:qeran/features/badges/domain/usecases/mark_tab_seen_usecase.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';

class _MockGet extends Mock implements GetBadgesUseCase {}

class _MockMarkSeen extends Mock implements MarkTabSeenUseCase {}

void main() {
  late _MockGet getBadges;
  late _MockMarkSeen markTabSeen;
  late BadgesCubit cubit;

  setUp(() {
    getBadges = _MockGet();
    markTabSeen = _MockMarkSeen();
    cubit = BadgesCubit(getBadges: getBadges, markTabSeen: markTabSeen);
  });

  tearDown(() => cubit.close());

  void stubGet(BadgeCounts counts) {
    when(
      () => getBadges(),
    ).thenAnswer((_) async => Right<Failure, BadgeCounts>(counts));
  }

  group('refresh', () {
    test('adopts the server counts', () async {
      stubGet(const BadgeCounts({BadgeTabKeys.likes: 3}));

      await cubit.refresh();

      expect(cubit.state.likes, 3);
    });

    // A badge sits on a tab that works regardless. Blanking the bar over a
    // dropped request would be a worse lie than showing a slightly stale dot.
    test('a failure keeps the counts already on screen', () async {
      stubGet(const BadgeCounts({BadgeTabKeys.likes: 3}));
      await cubit.refresh();

      when(() => getBadges()).thenAnswer(
        (_) async => const Left<Failure, BadgeCounts>(OfflineFailure()),
      );
      await cubit.refresh();

      expect(cubit.state.likes, 3);
    });

    // A resume refreshes, and the socket reconnect it causes refreshes again
    // a moment later. Two callers, one answer.
    test('concurrent callers share one request', () async {
      final gate = Completer<Either<Failure, BadgeCounts>>();
      var calls = 0;
      when(() => getBadges()).thenAnswer((_) {
        calls++;
        return gate.future;
      });

      final first = cubit.refresh();
      final second = cubit.refresh();
      gate.complete(const Right(BadgeCounts({BadgeTabKeys.likes: 3})));
      await Future.wait([first, second]);

      expect(calls, 1);
      expect(cubit.state.likes, 3);
    });

    // The slot has to free up, or the counts freeze at whatever the first
    // call returned for the rest of the session.
    test('a later refresh still hits the network', () async {
      stubGet(const BadgeCounts({BadgeTabKeys.likes: 1}));
      await cubit.refresh();
      stubGet(const BadgeCounts({BadgeTabKeys.likes: 8}));

      await cubit.refresh();

      expect(cubit.state.likes, 8);
    });
  });

  group('applyUpdate', () {
    // The event carries an absolute count. Adding would double whatever a
    // REST refresh had already counted moments earlier.
    test('assigns the count rather than adding to it', () {
      cubit.applyUpdate(BadgeTabKeys.likes, 3);
      cubit.applyUpdate(BadgeTabKeys.likes, 5);

      expect(cubit.state.likes, 5);
    });

    test('zero clears that tab', () {
      cubit.applyUpdate(BadgeTabKeys.chat, 4);
      cubit.applyUpdate(BadgeTabKeys.chat, 0);

      expect(cubit.state.chat, 0);
      expect(cubit.state.has(BadgeTabKeys.chat), isFalse);
    });

    test('leaves the other tabs untouched', () {
      cubit.applyUpdate(BadgeTabKeys.likes, 2);
      cubit.applyUpdate(BadgeTabKeys.chat, 7);

      expect(cubit.state.likes, 2);
      expect(cubit.state.chat, 7);
    });

    test('an unrecognised tab is carried, not thrown on', () {
      cubit.applyUpdate('somethingNewUnread', 4);

      expect(cubit.state.of('somethingNewUnread'), 4);
    });

    test('an empty key and a negative count are ignored', () {
      cubit.applyUpdate(BadgeTabKeys.likes, 3);
      cubit.applyUpdate('', 9);
      cubit.applyUpdate(BadgeTabKeys.chat, -2);

      expect(cubit.state.likes, 3);
      expect(cubit.state.chat, 0);
    });
  });

  group('markSeen', () {
    setUp(() {
      when(
        () => markTabSeen(any()),
      ).thenAnswer((_) async => const Right<Failure, Unit>(unit));
    });

    test('drops the dot before the server is told', () async {
      cubit.applyUpdate(BadgeTabKeys.likes, 3);

      final pending = cubit.markSeen(BadgeTabKeys.likes);
      expect(cubit.state.likes, 0, reason: 'optimistic, not awaited');

      await pending;
      verify(() => markTabSeen(BadgeTabKeys.likes)).called(1);
    });

    // The user did look at the tab. A failed call is not worth putting the
    // dot back over — the next refresh settles it either way.
    test('a failure does not restore the dot', () async {
      cubit.applyUpdate(BadgeTabKeys.likes, 3);
      when(
        () => markTabSeen(any()),
      ).thenAnswer((_) async => const Left<Failure, Unit>(OfflineFailure()));

      await cubit.markSeen(BadgeTabKeys.likes);

      expect(cubit.state.likes, 0);
    });

    test('a tab with no badge does not call the server at all', () async {
      await cubit.markSeen(BadgeTabKeys.likes);

      verifyNever(() => markTabSeen(any()));
    });
  });

  group('clear', () {
    // The cubit is a lazy singleton and outlives the session that filled it,
    // so sign-out has to empty it or the next account inherits these dots.
    test('drops every count', () {
      cubit.applyUpdate(BadgeTabKeys.likes, 3);
      cubit.applyUpdate(BadgeTabKeys.notifications, 9);

      cubit.clear();

      expect(cubit.state, const BadgeCounts.empty());
    });

    test('is a no-op when already empty', () {
      final seen = <BadgeCounts>[];
      final sub = cubit.stream.listen(seen.add);

      cubit.clear();

      expect(seen, isEmpty);
      sub.cancel();
    });
  });
}
