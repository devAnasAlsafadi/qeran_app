import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/basic_user.dart';
import '../entities/my_profile.dart';
import '../entities/profile_fetch_outcome.dart';

abstract interface class ProfileRepository {
  /// `GET /api/profile`. Owner-shape, full details including
  /// `email`, `profileStatus`, `hasAnsweredQuestions`,
  /// `images[isApproved]`.
  Future<Either<Failure, MyProfile>> getMyProfile();

  /// `GET /api/discovery/profiles/{userId}`. Other-user shape with
  /// `matchingScore` and `images[isBlurred]`. On the documented
  /// `PROFILE_NOT_FOUND` error, returns
  /// `Right(ProfileNotFoundOutcome)` — *not* a Left — so the UI can
  /// distinguish a missing profile from a transport failure.
  Future<Either<Failure, ProfileFetchOutcome>> getProfileById(String userId);

  /// `GET /api/users/{id}`. Lightweight tuple — no images, no
  /// placements. `null` on documented USER_NOT_FOUND.
  Future<Either<Failure, BasicUser?>> getBasicUser(String id);

  /// `DELETE /api/Profile`. Permanent, non-recoverable account deletion.
  /// `Right(unit)` on success; `Left(Failure)` on any error.
  Future<Either<Failure, Unit>> deleteAccount();
}
