import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/application/photo_view_session_clock.dart';
import 'package:qeran/features/likes/presentation/blocs/photo_view_state.dart';

import 'photo_view_race_harness.dart';

/// The other ordering of the same race. When a resume-triggered read wins the
/// scheduling slot, the phase reads `loading` at the moment the member
/// confirms — and the gate in `beginViewing` used to drop the press on the
/// floor with no POST, no error and no visible change. The member pressed
/// "إظهار الصور", agreed to spend their one irreversible opening, and nothing
/// happened at all.
///
/// The press now WAITS for the read instead of being judged against it. The
/// pair below is the point: waiting must let a legitimate press through, and
/// must still let the read refuse one. Deferring to the gate is not the same
/// as widening it.
void main() {
  test('a press that lands mid-read still opens the window', () async {
    final repository = RaceRepository();
    final cubit = cubitFor(repository, PhotoViewSessionClock());

    unawaited(cubit.load());
    await settle();
    repository.reads.last.complete(const Right(available));
    await settle();
    expect(cubit.state.phase, PhotoViewPhase.available);

    // A resume fires and re-verification goes out.
    unawaited(cubit.load());
    await settle();
    expect(
      cubit.state.phase,
      PhotoViewPhase.loading,
      reason: 'precondition: the phase the old gate rejected the press on',
    );

    // The member confirms while that read is still in flight.
    unawaited(cubit.beginViewing());
    await settle();
    expect(
      repository.posts,
      isEmpty,
      reason: 'precondition: the press is WAITING on the read, so this test '
          'really is the mid-read case and not a plain press',
    );

    repository.reads.last.complete(const Right(available));
    await settle();

    expect(
      repository.posts,
      hasLength(1),
      reason: 'the press was swallowed — the member spent their one opening '
          'on nothing at all',
    );
    repository.posts.last.complete(Right(session));
    await settle();
    expect(cubit.state.phase, PhotoViewPhase.viewing);
    await cubit.close();
  });

  test('a press deferred behind a read that REFUSES never posts', () async {
    final repository = RaceRepository();
    final cubit = cubitFor(repository, PhotoViewSessionClock());

    unawaited(cubit.load());
    await settle();
    repository.reads.last.complete(const Right(available));
    await settle();

    unawaited(cubit.load());
    await settle();
    unawaited(cubit.beginViewing());
    await settle();
    expect(repository.posts, isEmpty);

    // The read comes back saying the window is already gone.
    repository.reads.last.complete(Right(revoked));
    await settle();

    expect(
      repository.posts,
      isEmpty,
      reason: 'waiting for the read must not become permission to ignore it — '
          'this is the difference between DEFERRING to the gate and widening '
          'it to accept a stale exchangeId',
    );
    expect(cubit.state.phase, PhotoViewPhase.consumed);
    await cubit.close();
  });
}
