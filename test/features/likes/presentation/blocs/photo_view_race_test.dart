import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/likes/application/photo_view_session_clock.dart';
import 'package:qeran/features/likes/presentation/blocs/photo_view_state.dart';

import 'photo_view_race_harness.dart';

void main() {
  test('a read that predates the reveal cannot put the button back', () async {
    final repository = RaceRepository();
    final cubit = cubitFor(repository, PhotoViewSessionClock());

    unawaited(cubit.load());
    await settle();
    repository.reads.last.complete(const Right(available));
    await settle();
    expect(cubit.state.phase, PhotoViewPhase.available);

    // The member confirms. The POST is in flight.
    unawaited(cubit.beginViewing());
    await settle();
    expect(repository.posts, hasLength(1));

    // A resume fires while it is, so the GET goes out against a server that
    // has not recorded the reveal yet. This is the whole bug.
    unawaited(cubit.load());
    await settle();
    expect(
      repository.reads,
      hasLength(2),
      reason: 'the racing read never went out — nothing below is tested',
    );

    repository.posts.last.complete(Right(session));
    await settle();
    expect(
      cubit.state.phase,
      PhotoViewPhase.viewing,
      reason: 'precondition: the reveal landed and the window opened',
    );

    repository.reads.last.complete(const Right(available));
    await settle();

    expect(
      cubit.state.phase,
      PhotoViewPhase.viewing,
      reason: 'the stale read undid the reveal — the member watched the '
          'button reappear over photos they had just spent their one '
          'opening on',
    );
    await cubit.close();
  });

  test('a read that FAILS after the reveal cannot close the window', () async {
    final repository = RaceRepository();
    final cubit = cubitFor(repository, PhotoViewSessionClock());

    unawaited(cubit.load());
    await settle();
    repository.reads.last.complete(const Right(available));
    await settle();

    unawaited(cubit.beginViewing());
    await settle();
    unawaited(cubit.load());
    await settle();
    repository.posts.last.complete(Right(session));
    await settle();

    repository.reads.last.complete(
      const Left(ServerFailure(message: 'errors.generic')),
    );
    await settle();

    expect(
      cubit.state.phase,
      PhotoViewPhase.viewing,
      reason: 'the guard has to sit ahead of the fold — a stale FAILURE is '
          'just as capable of clobbering the open window as a stale success',
    );
    await cubit.close();
  });

  group('re-verification is never what gets dropped', () {
    // 🔴 The security half. "Drop reads older than the newest fact" and
    // "ignore reads while viewing" are indistinguishable on the test above.
    // They part company here, and the second one is a leak: it swallows the
    // resume-time read that catches a REVOKED window and keeps rendering
    // clear photos afterwards.
    test('a revoked window closes even with no reveal in this cubit', () async {
      final repository = RaceRepository();
      final cubit = cubitFor(repository, PhotoViewSessionClock());

      // Reached through `load` alone, so nothing has ever bumped the counter.
      unawaited(cubit.load());
      await settle();
      repository.reads.last.complete(Right(openWindow));
      await settle();
      expect(
        cubit.state.phase,
        PhotoViewPhase.viewing,
        reason: 'precondition: a window is open and no POST was ever made',
      );

      unawaited(cubit.load());
      await settle();
      repository.reads.last.complete(Right(revoked));
      await settle();

      expect(
        cubit.state.phase,
        PhotoViewPhase.consumed,
        reason: 'the server revoked the window and the guard swallowed the '
            'news — clear photos keep rendering. This is the leak.',
      );
      await cubit.close();
    });

    test('a revoked window closes after a reveal too', () async {
      final repository = RaceRepository();
      final cubit = cubitFor(repository, PhotoViewSessionClock());

      unawaited(cubit.load());
      await settle();
      repository.reads.last.complete(const Right(available));
      await settle();
      unawaited(cubit.beginViewing());
      await settle();
      repository.posts.last.complete(Right(session));
      await settle();
      expect(cubit.state.phase, PhotoViewPhase.viewing);

      // Issued AFTER the reveal, so it is not stale and must land. A guard
      // that remembered only "a reveal happened" would drop this one too.
      unawaited(cubit.load());
      await settle();
      repository.reads.last.complete(Right(revoked));
      await settle();

      expect(
        cubit.state.phase,
        PhotoViewPhase.consumed,
        reason: 'the guard keys on ISSUE ORDER, not on whether a reveal has '
            'ever happened — a read newer than the reveal still speaks',
      );
      await cubit.close();
    });
  });
}
