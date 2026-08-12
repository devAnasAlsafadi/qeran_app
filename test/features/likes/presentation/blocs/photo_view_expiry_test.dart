import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/likes/application/photo_view_session_clock.dart';
import 'package:qeran/features/likes/domain/entities/photo_view_permission.dart';
import 'package:qeran/features/likes/domain/entities/photo_view_session.dart';
import 'package:qeran/features/likes/domain/repositories/photo_view_repository.dart';
import 'package:qeran/features/likes/domain/usecases/begin_photo_view_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/get_photo_view_permission_usecase.dart';
import 'package:qeran/features/likes/presentation/blocs/photo_view_cubit.dart';
import 'package:qeran/features/likes/presentation/blocs/photo_view_state.dart';

/// The visible countdown badge is gone, so the close of the 60-second window
/// is the only thing left to tell the member their view has ended. It must
/// fire exactly when they were watching — and never otherwise.
class _FakeRepo implements PhotoViewRepository {
  Either<Failure, PhotoViewPermission> permissionResult;
  Either<Failure, PhotoViewSession> sessionResult;

  _FakeRepo({required this.permissionResult, required this.sessionResult});

  @override
  Future<Either<Failure, PhotoViewPermission>> getPermission(String _) async =>
      permissionResult;

  @override
  Future<Either<Failure, PhotoViewSession>> beginView(int _) async =>
      sessionResult;
}

const _available = PhotoViewPermission(
  targetUserId: 'u1',
  photoExchangeId: 42,
  isUnblurred: false,
  viewedAt: null,
  viewExpiresAt: null,
  isConsumed: false,
);

const _consumed = PhotoViewPermission(
  targetUserId: 'u1',
  photoExchangeId: 42,
  isUnblurred: false,
  viewedAt: null,
  viewExpiresAt: null,
  isConsumed: true,
);

final _session = PhotoViewSession(
  photoExchangeId: 42,
  viewedAt: DateTime.utc(2026, 8, 11, 18, 20),
  viewExpiresAt: DateTime.utc(2026, 8, 11, 18, 21),
  secondsRemaining: 60,
);

PhotoViewCubit _build(_FakeRepo repo) => PhotoViewCubit(
  targetUserId: 'u1',
  getPermission: GetPhotoViewPermissionUseCase(repo),
  beginView: BeginPhotoViewUseCase(repo),
  sessionClock: PhotoViewSessionClock(),
);

void main() {
  test('the window closing while viewing raises the expiry event', () async {
    final repo = _FakeRepo(
      permissionResult: const Right(_available),
      sessionResult: Right(_session),
    );
    final cubit = _build(repo);
    await cubit.load();
    await cubit.beginViewing();
    expect(cubit.state.phase, PhotoViewPhase.viewing);
    final before = cubit.state.eventVersion;

    // What the ticker does when the clock runs out.
    cubit.markImageAccessConsumed();

    expect(cubit.state.phase, PhotoViewPhase.consumed);
    expect(cubit.state.justExpired, isTrue);
    expect(
      cubit.state.eventVersion,
      before + 1,
      reason: 'the host listens on the version to show the message once',
    );
    await cubit.close();
  });

  test('a lock before any reveal is not announced as an expiry', () async {
    // A 403 on an image the member never revealed is not something they
    // witnessed ending — telling them their viewing period ended would be
    // describing an event that did not happen to them.
    final repo = _FakeRepo(
      permissionResult: const Right(_available),
      sessionResult: Right(_session),
    );
    final cubit = _build(repo);
    await cubit.load();
    expect(cubit.state.phase, PhotoViewPhase.available);
    final before = cubit.state.eventVersion;

    cubit.markImageAccessConsumed();

    expect(cubit.state.phase, PhotoViewPhase.consumed);
    expect(cubit.state.justExpired, isFalse);
    expect(cubit.state.eventVersion, before);
    await cubit.close();
  });

  test('an already-consumed permission announces nothing on load', () async {
    // Reopening a match whose window was spent days ago must be silent.
    final repo = _FakeRepo(
      permissionResult: const Right(_consumed),
      sessionResult: Right(_session),
    );
    final cubit = _build(repo);

    await cubit.load();

    expect(cubit.state.phase, PhotoViewPhase.consumed);
    expect(cubit.state.justExpired, isFalse);
    await cubit.close();
  });

  test('a second lock call after expiry does not re-announce', () async {
    final repo = _FakeRepo(
      permissionResult: const Right(_available),
      sessionResult: Right(_session),
    );
    final cubit = _build(repo);
    await cubit.load();
    await cubit.beginViewing();
    cubit.markImageAccessConsumed();
    final afterFirst = cubit.state.eventVersion;

    cubit.markImageAccessConsumed();

    expect(cubit.state.eventVersion, afterFirst);
    await cubit.close();
  });
}
