import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/server_clock.dart';
import 'package:qeran/features/likes/domain/entities/like_request_card.dart';
import 'package:qeran/features/likes/domain/entities/like_request_status.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_direction.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_pending.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_status.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_photo_exchange.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_photo_exchange_status.dart';
import 'package:qeran/features/matchmaker/interests/domain/entities/matchmaker_interest_enums.dart';
import 'package:qeran/features/matchmaker/interests/domain/entities/matchmaker_interest_like.dart';

/// One behaviour change, four entities, both apps.
///
/// The backend used to null `expiresAt` once a request lapsed, so "Pending
/// with a deadline" was a safe shorthand for "still running". It now returns
/// the real timestamp whatever the outcome, and a lapsed request keeps its
/// Pending status until the server sweeps it — so the shorthand became a bug
/// that paints a live countdown and live buttons on a dead row.
///
/// Every one of these types must answer the same way, or the two apps disagree
/// about a single request.

final _past = DateTime.now().toUtc().subtract(const Duration(hours: 2));
final _future = DateTime.now().toUtc().add(const Duration(hours: 2));

LikeRequestCard _like({
  required LikeRequestStatus status,
  DateTime? expiresAt,
}) => LikeRequestCard(
  likeRequestId: 1,
  profileId: 'p',
  name: 'A',
  profileImage: null,
  status: status,
  createdAt: null,
  remainingSeconds: null,
  expiresAt: expiresAt,
  actions: const ['accept', 'reject'],
  isLocked: false,
);

MatchmakerInterestLike _mirror({
  required MatchmakerInterestLikeStatus status,
  DateTime? expiresAt,
}) => MatchmakerInterestLike(
  otherUserId: 'u',
  name: 'A',
  image: null,
  status: status,
  isLocked: false,
  expiresAt: expiresAt,
);

PhotoExchangePending _exchange({
  required PhotoExchangeStatus status,
  required DateTime expiresAt,
}) => PhotoExchangePending(
  id: 1,
  likeRequestId: 2,
  initiatorId: 'a',
  responderId: 'b',
  status: status,
  statusCode: 0,
  remainingSeconds: null,
  createdAt: DateTime.now().toUtc(),
  expiresAt: expiresAt,
  direction: PhotoExchangeDirection.received,
  requestedByMe: false,
  canAccept: true,
  canReject: true,
);

CasePhotoExchange _caseExchange({
  required CasePhotoExchangeStatus status,
  DateTime? expiresAt,
}) => CasePhotoExchange(
  requestId: 1,
  status: status,
  respondedAt: null,
  initiatorId: null,
  responderId: null,
  expiresAt: expiresAt,
);

void main() {
  setUp(ServerClock.resetForTest);

  group('pending is no longer enough on its own', () {
    test('a like row', () {
      expect(
        _like(
          status: LikeRequestStatus.pending,
          expiresAt: _future,
        ).isAwaitingResponse,
        isTrue,
      );
      // The regression: same status, deadline behind us.
      expect(
        _like(
          status: LikeRequestStatus.pending,
          expiresAt: _past,
        ).isAwaitingResponse,
        isFalse,
      );
    });

    test("the matchmaker's mirror of that same row agrees", () {
      expect(
        _mirror(
          status: MatchmakerInterestLikeStatus.pending,
          expiresAt: _future,
        ).isAwaitingResponse,
        isTrue,
      );
      expect(
        _mirror(
          status: MatchmakerInterestLikeStatus.pending,
          expiresAt: _past,
        ).isAwaitingResponse,
        isFalse,
      );
    });

    test('a /api/matches photo exchange', () {
      expect(
        _exchange(
          status: PhotoExchangeStatus.pending,
          expiresAt: _future,
        ).isAwaitingResponse,
        isTrue,
      );
      expect(
        _exchange(
          status: PhotoExchangeStatus.pending,
          expiresAt: _past,
        ).isAwaitingResponse,
        isFalse,
      );
    });

    test('a compatibility-case photo exchange', () {
      expect(
        _caseExchange(
          status: CasePhotoExchangeStatus.pending,
          expiresAt: _future,
        ).isAwaitingResponse,
        isTrue,
      );
      expect(
        _caseExchange(
          status: CasePhotoExchangeStatus.pending,
          expiresAt: _past,
        ).isAwaitingResponse,
        isFalse,
      );
    });
  });

  group('a non-pending status is never live, deadline notwithstanding', () {
    test('across all four', () {
      expect(
        _like(
          status: LikeRequestStatus.accepted,
          expiresAt: _future,
        ).isAwaitingResponse,
        isFalse,
      );
      expect(
        _mirror(
          status: MatchmakerInterestLikeStatus.rejected,
          expiresAt: _future,
        ).isAwaitingResponse,
        isFalse,
      );
      expect(
        _exchange(
          status: PhotoExchangeStatus.accepted,
          expiresAt: _future,
        ).isAwaitingResponse,
        isFalse,
      );
      expect(
        _caseExchange(
          status: CasePhotoExchangeStatus.expired,
          expiresAt: _future,
        ).isAwaitingResponse,
        isFalse,
      );
    });
  });

  group('rollout safety — a payload without the field still works', () {
    test('pending with no deadline stays live rather than blanking', () {
      // Partial rollout or cached data: absence means "this payload carried
      // no deadline", never "it expired". Reading it as expired would hide
      // every live row on an older response.
      expect(
        _like(status: LikeRequestStatus.pending).isAwaitingResponse,
        isTrue,
      );
      expect(
        _mirror(
          status: MatchmakerInterestLikeStatus.pending,
        ).isAwaitingResponse,
        isTrue,
      );
      expect(
        _caseExchange(
          status: CasePhotoExchangeStatus.pending,
        ).isAwaitingResponse,
        isTrue,
      );
    });
  });

  group('the verdict follows the server clock, not the device', () {
    test('a deadline in the device future can already be lapsed', () {
      final deviceNow = DateTime.now().toUtc();
      // Device is an hour behind the server.
      ServerClock.instance.calibrate(
        expiresAt: deviceNow.add(const Duration(hours: 1, minutes: 10)),
        remainingSeconds: 600,
      );

      final card = _like(
        status: LikeRequestStatus.pending,
        expiresAt: deviceNow.add(const Duration(minutes: 30)),
      );

      expect(card.isAwaitingResponse, isFalse);
    });
  });
}
