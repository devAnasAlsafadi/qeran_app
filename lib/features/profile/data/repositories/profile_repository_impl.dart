import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/basic_user.dart';
import '../../domain/entities/my_profile.dart';
import '../../domain/entities/profile_fetch_outcome.dart';
import '../../domain/entities/profile_image.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl
    with BaseRepository
    implements ProfileRepository {
  final ProfileRemoteDataSource _dataSource;

  const ProfileRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, MyProfile>> getMyProfile() {
    return executeApiCall(() async {
      final model = await _dataSource.getMyProfile();
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, MyProfile>> updateProfile({
    required String displayName,
    String? realName,
  }) {
    return executeApiCall(() async {
      final model = await _dataSource.updateProfile(
        displayName: displayName,
        realName: realName,
      );
      return model.toEntity();
    });
  }

  @override
  Future<Either<Failure, ProfileFetchOutcome>> getProfileById(String userId) {
    // Datasource returns a typed result so PROFILE_NOT_FOUND lands on
    // the Right branch (a missing profile is an expected business
    // outcome, not a transport failure). Anything else — 401, 5xx,
    // unknown errorCode — bubbles via executeApiCall.
    return executeApiCall(() async {
      final result = await _dataSource.getProfileById(userId);
      return switch (result) {
        GetProfileByIdSuccess(:final model) =>
            ProfileFetched(model.toEntity()),
        GetProfileByIdNotFound(:final message) =>
            ProfileNotFoundOutcome(serverMessage: message),
      };
    });
  }

  @override
  Future<Either<Failure, BasicUser?>> getBasicUser(String id) {
    return executeApiCall(() async {
      final model = await _dataSource.getBasicUser(id);
      return model?.toEntity();
    });
  }

  @override
  Future<Either<Failure, List<OwnerImage>>> getProfileImages() {
    return executeApiCall(() async {
      final models = await _dataSource.getProfileImages();
      return models.map((model) => model.toEntity()).toList(growable: false);
    });
  }

  @override
  Future<Either<Failure, List<OwnerImage>>> addProfileImages(
    List<File> images,
  ) {
    return executeApiCall(() async {
      final models = await _dataSource.addProfileImages(images);
      return models.map((model) => model.toEntity()).toList(growable: false);
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteProfileImage(String imageId) {
    return executeApiCall(() async {
      await _dataSource.deleteProfileImage(imageId);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> setMainProfileImage(String imageId) {
    return executeApiCall(() async {
      await _dataSource.setMainProfileImage(imageId);
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteAccount() {
    return executeApiCall(() async {
      await _dataSource.deleteAccount();
      return unit;
    });
  }
}
