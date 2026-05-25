import 'package:dartz/dartz.dart';

import 'package:qeran/core/errors/errors.dart';

import '../entities/match_card.dart';
import '../entities/photo_exchange_outcome.dart';

/// Domain-layer contract for the Matches tab.
///
/// `/api/matches` returns the full list of active relationships post
/// like-acceptance (stages 0/1/2). Archive is intentionally not part
/// of this contract — it's a future feature with its own endpoint.
///
/// The photo-exchange action methods return typed outcomes so the
/// cubit can branch (paywall vs snackbar vs refresh) without inspecting
/// raw backend messages.
abstract interface class MatchesRepository {
  /// `GET /api/matches` — list of active matches.
  Future<Either<Failure, List<MatchCard>>> getMatches();

  /// `POST /api/photo-exchange/request/{likeRequestId}` — initiator.
  /// Subscription-gated.
  Future<Either<Failure, PhotoExchangeRequestOutcome>> requestPhotoExchange(
    int likeRequestId,
  );

  /// `POST /api/photo-exchange/{requestId}/accept` — responder.
  /// `requestId` is `pendingPhotoExchange.id`, NOT the like id.
  Future<Either<Failure, PhotoExchangeRespondOutcome>> acceptPhotoExchange(
    int requestId,
  );

  /// `POST /api/photo-exchange/{requestId}/reject` — responder.
  /// Pushes the relationship to the matchmaker (stage 2). Does NOT
  /// archive.
  Future<Either<Failure, PhotoExchangeRespondOutcome>> rejectPhotoExchange(
    int requestId,
  );
}
