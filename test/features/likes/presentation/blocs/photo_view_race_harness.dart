import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/likes/application/photo_view_session_clock.dart';
import 'package:qeran/features/likes/domain/entities/photo_view_permission.dart';
import 'package:qeran/features/likes/domain/entities/photo_view_session.dart';
import 'package:qeran/features/likes/domain/repositories/photo_view_repository.dart';
import 'package:qeran/features/likes/domain/usecases/begin_photo_view_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/get_photo_view_permission_usecase.dart';
import 'package:qeran/features/likes/presentation/blocs/photo_view_cubit.dart';

/// The reveal POST and the permission GET are two writers to one state, and
/// nothing used to order them. A GET issued before the POST landed answers
/// from a snapshot where the window was never opened, and `_applyPermission`
/// replaces the WHOLE state — so it put the reveal button back over photos the
/// member had just paid their one opening for.
///
/// The guard is keyed on ISSUE ORDER, and the distinction is the whole point:
/// "drop reads older than the newest fact" and "ignore reads while viewing"
/// behave identically on the bug above, and only the first one still catches a
/// window the server has REVOKED. The second would keep rendering clear photos
/// after revocation, which is why [revoked] appears here twice.
class RaceRepository implements PhotoViewRepository {
  final List<Completer<Either<Failure, PhotoViewPermission>>> reads = [];
  final List<Completer<Either<Failure, PhotoViewSession>>> posts = [];

  @override
  Future<Either<Failure, PhotoViewPermission>> getPermission(
    String targetUserId,
  ) {
    final completer = Completer<Either<Failure, PhotoViewPermission>>();
    reads.add(completer);
    return completer.future;
  }

  @override
  Future<Either<Failure, PhotoViewSession>> beginView(int photoExchangeId) {
    final completer = Completer<Either<Failure, PhotoViewSession>>();
    posts.add(completer);
    return completer.future;
  }
}

/// Accepted, never opened — the state the reveal button belongs to. This is
/// also the STALE answer: a read issued before the POST returns exactly this.
const available = PhotoViewPermission(
  targetUserId: 'u1',
  photoExchangeId: 42,
  isUnblurred: false,
  viewedAt: null,
  viewExpiresAt: null,
  isConsumed: false,
);

/// A window the server says is open, with the seconds needed to resume it —
/// so `load` alone can reach `viewing` with NO reveal in this cubit's history.
final openWindow = PhotoViewPermission(
  targetUserId: 'u1',
  photoExchangeId: 42,
  isUnblurred: true,
  viewedAt: DateTime.utc(2026, 9, 4, 10),
  viewExpiresAt: DateTime.utc(2026, 9, 4, 10, 1),
  isConsumed: false,
  secondsRemaining: 60,
);

/// The window the server has closed. A re-verification carrying this must
/// ALWAYS land, whatever else the cubit is doing.
final revoked = PhotoViewPermission(
  targetUserId: 'u1',
  photoExchangeId: 42,
  isUnblurred: false,
  viewedAt: DateTime.utc(2026, 9, 4, 10),
  viewExpiresAt: DateTime.utc(2026, 9, 4, 10, 1),
  isConsumed: true,
);

final session = PhotoViewSession(
  photoExchangeId: 42,
  viewedAt: DateTime.utc(2026, 9, 4, 10),
  viewExpiresAt: DateTime.utc(2026, 9, 4, 10, 1),
  secondsRemaining: 60,
);

PhotoViewCubit cubitFor(RaceRepository repository, PhotoViewSessionClock c) =>
    PhotoViewCubit(
      targetUserId: 'u1',
      getPermission: GetPhotoViewPermissionUseCase(repository),
      beginView: BeginPhotoViewUseCase(repository),
      sessionClock: c,
    );

/// One turn of the event loop, which flushes every pending microtask — the
/// awaits inside the cubit resolve on this.
Future<void> settle() => Future<void>.delayed(Duration.zero);
