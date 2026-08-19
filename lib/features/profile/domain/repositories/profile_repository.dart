import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/basic_user.dart';
import '../entities/my_profile.dart';
import '../entities/profile_fetch_outcome.dart';
import '../entities/profile_image.dart';

abstract interface class ProfileRepository {
  /// `GET /api/profile`. Owner-shape, full details including
  /// `email`, `profileStatus`, `hasAnsweredQuestions`, `images`.
  Future<Either<Failure, MyProfile>> getMyProfile();

  /// `PUT /api/profile`. Sets both names and returns the complete updated
  /// profile, so callers refresh from the result rather than re-reading.
  ///
  /// [displayName] is required. [realName] null leaves the stored value
  /// untouched; `''` clears it.
  Future<Either<Failure, MyProfile>> updateProfile({
    required String displayName,
    String? realName,
  });

  /// `GET /api/discovery/profiles/{userId}`. Other-user shape with
  /// `matchingScore` and `images[isBlurred]`. On the documented
  /// `PROFILE_NOT_FOUND` error, returns
  /// `Right(ProfileNotFoundOutcome)` — *not* a Left — so the UI can
  /// distinguish a missing profile from a transport failure.
  Future<Either<Failure, ProfileFetchOutcome>> getProfileById(String userId);

  /// `GET /api/users/{id}`. Lightweight tuple — no images, no
  /// placements. `null` on documented USER_NOT_FOUND.
  Future<Either<Failure, BasicUser?>> getBasicUser(String id);

  Future<Either<Failure, List<OwnerImage>>> getProfileImages();
  /// Returns the images CREATED by this request (not the full library), so a
  /// caller can act on a new photo's server id without diffing the list.
  Future<Either<Failure, List<OwnerImage>>> addProfileImages(List<File> images);
  Future<Either<Failure, Unit>> deleteProfileImage(String imageId);
  Future<Either<Failure, Unit>> setMainProfileImage(String imageId);

  /// `DELETE /api/Profile`. Permanent, non-recoverable account deletion.
  /// `Right(unit)` on success; `Left(Failure)` on any error.
  Future<Either<Failure, Unit>> deleteAccount();
}
