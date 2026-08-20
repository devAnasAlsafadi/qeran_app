import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/discovery_filter_question.dart';
import '../entities/discovery_page.dart';
import '../entities/like_outcome.dart';

abstract interface class DiscoveryRepository {
  /// Fetches one page of Discovery profiles.
  ///
  /// [filterParams] is the already-flat query map produced by
  /// `DiscoveryFilterCubit.buildPayload()` (keys like `RangeFrom[5]`,
  /// `QuestionFilters[18]`). Pass `null` for an unconstrained fetch.
  Future<Either<Failure, DiscoveryPage>> fetchPage({
    int page,
    int pageSize,
    Map<String, String>? filterParams,
  });

  /// Records a "like" against [profileId].
  ///
  /// Semantic outcomes the server can return (subscription/limit
  /// exhausted, already pending, gender mismatch, user gone) come back
  /// on the `Right` side as typed [LikeOutcome] variants. The `Left`
  /// side is reserved for transport-level problems (network, timeout,
  /// parse, auth, unrecognised server message).
  Future<Either<Failure, LikeOutcome>> likeProfile(String profileId);

  /// Records a "pass" (skip) against [profileId]. Skip is permanent
  /// server-side — the user will never see this profile again in
  /// Discovery. No subscription gate, no limit, no notification.
  Future<Either<Failure, Unit>> passProfile(String profileId);

  /// Puts every profile this user skipped back into the deck, and reports how
  /// many came back.
  ///
  /// `Right(0)` is a successful no-op — the user had skipped nobody — and is
  /// deliberately distinct from `Left(Failure)` so the UI can say "nothing to
  /// restore" instead of reloading an unchanged deck in silence.
  ///
  /// Likes are untouched: on the server, skips and saved profiles are one
  /// table separated by a flag, and only the skipped rows are removed.
  Future<Either<Failure, int>> resetSkippedProfiles();

  /// Fetches the dynamic filter questions surfaced on the filters sheet.
  /// The backend (dashboard) controls which questions appear and in what
  /// order — the app never hardcodes question ids.
  Future<Either<Failure, List<DiscoveryFilterQuestion>>> getFilters();
}
