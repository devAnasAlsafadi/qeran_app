import 'package:dartz/dartz.dart';

import 'package:qeran/core/errors/errors.dart';

import '../entities/like_action_outcome.dart';
import '../entities/like_requests_data.dart';

/// Domain-layer contract for the Likes feature.
///
/// Backed by `LikesRepositoryImpl` + `LikesRemoteDataSource` over the
/// two GET endpoints `/api/likes/incoming` and `/api/likes/outgoing`
/// and the two POST endpoints `/api/likes/{id}/accept` and
/// `/api/likes/{id}/reject`. Accept / reject return a typed
/// [LikeActionOutcome] on the `Right` so the cubit can branch between
/// success, paywall, expired, and not-found without inspecting raw
/// server messages.
abstract interface class LikesRepository {
  /// `GET /api/likes/incoming` — people who liked me. Locked for
  /// non-subscribers (identity redacted, no actions).
  Future<Either<Failure, LikeRequestsData>> getIncoming();

  /// `GET /api/likes/outgoing` — people I liked. Identity always
  /// visible (the server reveals the receiver because I'm the one who
  /// initiated the like).
  Future<Either<Failure, LikeRequestsData>> getOutgoing();

  /// `POST /api/likes/{likeRequestId}/accept` — subscription-gated.
  /// Returns a typed outcome; transport / unknown failures stay on
  /// the `Left` side as `Failure`.
  Future<Either<Failure, LikeActionOutcome>> acceptLike(int likeRequestId);

  /// `POST /api/likes/{likeRequestId}/reject` — no subscription gate.
  Future<Either<Failure, LikeActionOutcome>> rejectLike(int likeRequestId);
}
