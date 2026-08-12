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

class _FakePhotoViewRepository implements PhotoViewRepository {
  Either<Failure, PhotoViewPermission> permissionResult;
  Either<Failure, PhotoViewSession> sessionResult;
  int beginCalls = 0;

  _FakePhotoViewRepository({
    required this.permissionResult,
    required this.sessionResult,
  });

  @override
  Future<Either<Failure, PhotoViewPermission>> getPermission(
    String targetUserId,
  ) async => permissionResult;

  @override
  Future<Either<Failure, PhotoViewSession>> beginView(
    int photoExchangeId,
  ) async {
    beginCalls += 1;
    return sessionResult;
  }
}

const _available = PhotoViewPermission(
  targetUserId: 'u1',
  photoExchangeId: 42,
  isUnblurred: false,
  viewedAt: null,
  viewExpiresAt: null,
  isConsumed: false,
);

final _active = PhotoViewPermission(
  targetUserId: 'u1',
  photoExchangeId: 42,
  isUnblurred: true,
  viewedAt: DateTime.utc(2026, 8, 11, 18, 20),
  viewExpiresAt: DateTime.utc(2026, 8, 11, 18, 21),
  isConsumed: false,
);

final _session = PhotoViewSession(
  photoExchangeId: 42,
  viewedAt: DateTime.utc(2026, 8, 11, 18, 20),
  viewExpiresAt: DateTime.utc(2026, 8, 11, 18, 21),
  secondsRemaining: 60,
);

PhotoViewCubit _cubit(
  _FakePhotoViewRepository repository,
  PhotoViewSessionClock clock,
) => PhotoViewCubit(
  targetUserId: 'u1',
  getPermission: GetPhotoViewPermissionUseCase(repository),
  beginView: BeginPhotoViewUseCase(repository),
  sessionClock: clock,
);

void main() {
  test('loading permission never starts the irreversible POST', () async {
    final repository = _FakePhotoViewRepository(
      permissionResult: const Right(_available),
      sessionResult: Right(_session),
    );
    final cubit = _cubit(repository, PhotoViewSessionClock());

    await cubit.load();

    expect(cubit.state.phase, PhotoViewPhase.available);
    expect(repository.beginCalls, 0);
    await cubit.close();
  });

  test('button action starts viewing with server seconds', () async {
    final repository = _FakePhotoViewRepository(
      permissionResult: const Right(_available),
      sessionResult: Right(_session),
    );
    final cubit = _cubit(repository, PhotoViewSessionClock());
    await cubit.load();

    await cubit.beginViewing();

    expect(repository.beginCalls, 1);
    expect(cubit.state.phase, PhotoViewPhase.viewing);
    expect(cubit.state.secondsRemaining, 60);
    await cubit.close();
  });

  test('a reopened route resumes the same monotonic window', () async {
    final clock = PhotoViewSessionClock();
    final repository = _FakePhotoViewRepository(
      permissionResult: const Right(_available),
      sessionResult: Right(_session),
    );
    final first = _cubit(repository, clock);
    await first.load();
    await first.beginViewing();
    await first.close();

    repository.permissionResult = Right(_active);
    final reopened = _cubit(repository, clock);
    await reopened.load();

    expect(reopened.state.phase, PhotoViewPhase.viewing);
    expect(reopened.state.secondsRemaining, inInclusiveRange(59, 60));
    expect(
      repository.beginCalls,
      1,
      reason: 'reopen must not POST /view again',
    );
    await reopened.close();
  });

  test('consumed permission is terminal and never starts viewing', () async {
    final consumed = PhotoViewPermission(
      targetUserId: 'u1',
      photoExchangeId: 42,
      isUnblurred: false,
      viewedAt: DateTime.utc(2026, 8, 11, 18, 20),
      viewExpiresAt: DateTime.utc(2026, 8, 11, 18, 21),
      isConsumed: true,
    );
    final repository = _FakePhotoViewRepository(
      permissionResult: Right(consumed),
      sessionResult: Right(_session),
    );
    final cubit = _cubit(repository, PhotoViewSessionClock());

    await cubit.load();
    await cubit.beginViewing();

    expect(cubit.state.phase, PhotoViewPhase.consumed);
    expect(repository.beginCalls, 0);
    await cubit.close();
  });
}
