import 'dart:io';

import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../models/basic_user_model.dart';
import '../models/my_profile_model.dart';
import '../models/other_profile_model.dart';
import '../models/owner_image_model.dart';

/// Typed outcomes for `getProfileById` so the repository can branch on
/// `PROFILE_NOT_FOUND` without losing the rest of `ServerException`.
sealed class GetProfileByIdResult {
  const GetProfileByIdResult();
}

final class GetProfileByIdSuccess extends GetProfileByIdResult {
  final OtherProfileModel model;
  const GetProfileByIdSuccess(this.model);
}

final class GetProfileByIdNotFound extends GetProfileByIdResult {
  final String message;
  const GetProfileByIdNotFound(this.message);
}

abstract interface class ProfileRemoteDataSource {
  Future<MyProfileModel> getMyProfile();

  /// `PUT /api/profile` with `{displayName, realName?}`. Returns the complete
  /// updated profile the server responded with — the caller must not refetch.
  ///
  /// [realName] null omits the key entirely (leave unchanged); `''` clears the
  /// stored value. The caller decides which of the two it means.
  Future<MyProfileModel> updateProfile({
    required String displayName,
    String? realName,
  });
  Future<GetProfileByIdResult> getProfileById(String userId);
  Future<BasicUserModel?> getBasicUser(String id);
  Future<List<OwnerImageModel>> getProfileImages();
  Future<void> addProfileImages(List<File> images);
  Future<void> deleteProfileImage(String imageId);
  Future<void> setMainProfileImage(String imageId);

  /// `DELETE /api/Profile` — permanent, non-recoverable account deletion
  /// (no body). `delete()` enforces the status envelope, so a failure throws
  /// a [ServerException]; success returns nothing.
  Future<void> deleteAccount();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiConsumer _apiConsumer;
  final StorageService _secureStorage;

  const ProfileRemoteDataSourceImpl({
    required ApiConsumer apiConsumer,
    required StorageService secureStorage,
  }) : _apiConsumer = apiConsumer,
       _secureStorage = secureStorage;

  @override
  Future<MyProfileModel> getMyProfile() async {
    AppLogger.debug('FETCH MY PROFILE', tag: 'PROFILE');
    final response = await _apiConsumer.get(EndPoints.myProfile);
    final apiResponse = ApiResponse<MyProfileModel>.fromJson(
      response as Map<String, dynamic>,
      (json) => MyProfileModel.fromJson(json as Map<String, dynamic>),
    );
    if (apiResponse.data == null) {
      throw ServerException(
        message: apiResponse.message ?? LocaleKeys.errors_generic,
      );
    }
    AppLogger.info('My profile fetched', tag: 'PROFILE');
    return apiResponse.data!;
  }

  @override
  Future<MyProfileModel> updateProfile({
    required String displayName,
    String? realName,
  }) async {
    // The three realName intents are worth telling apart in a log: an omitted
    // key, an explicit clear, and a new value are three different writes.
    final intent = switch (realName) {
      null => 'unchanged',
      '' => 'cleared',
      _ => 'set',
    };
    AppLogger.debug('UPDATE PROFILE realName=$intent', tag: 'PROFILE');
    // `displayName` is required on every call. `realName` is omitted entirely
    // when null — the server reads a missing key as "leave unchanged", which
    // an explicit null would NOT mean.
    final response = await _apiConsumer.put(
      EndPoints.updateProfile,
      body: {'displayName': displayName, 'realName': ?realName},
    );
    final apiResponse = ApiResponse<MyProfileModel>.fromJson(
      response as Map<String, dynamic>,
      (json) => MyProfileModel.fromJson(json as Map<String, dynamic>),
    );
    if (apiResponse.data == null) {
      throw ServerException(
        message: apiResponse.message ?? LocaleKeys.errors_generic,
      );
    }
    AppLogger.info('Profile names updated', tag: 'PROFILE');
    return apiResponse.data!;
  }

  @override
  Future<GetProfileByIdResult> getProfileById(String userId) async {
    AppLogger.debug('FETCH PROFILE BY ID -> $userId', tag: 'PROFILE');
    try {
      final response = await _apiConsumer.get(EndPoints.profileById(userId));
      final apiResponse = ApiResponse<OtherProfileModel>.fromJson(
        response as Map<String, dynamic>,
        (json) => OtherProfileModel.fromJson(json as Map<String, dynamic>),
      );
      if (apiResponse.data == null) {
        throw ServerException(
          message: apiResponse.message ?? LocaleKeys.errors_generic,
        );
      }
      AppLogger.info('Profile fetched id=$userId', tag: 'PROFILE');
      return GetProfileByIdSuccess(apiResponse.data!);
    } on CodedServerException catch (e) {
      if (e.errorCode == 'PROFILE_NOT_FOUND') {
        AppLogger.warning(
          'Profile not found id=$userId message="${e.message}"',
          tag: 'PROFILE',
        );
        return GetProfileByIdNotFound(e.message);
      }
      rethrow;
    }
  }

  @override
  Future<BasicUserModel?> getBasicUser(String id) async {
    AppLogger.debug('FETCH BASIC USER -> $id', tag: 'PROFILE');
    try {
      final response = await _apiConsumer.get(EndPoints.userBasic(id));
      final apiResponse = ApiResponse<BasicUserModel>.fromJson(
        response as Map<String, dynamic>,
        (json) => BasicUserModel.fromJson(json as Map<String, dynamic>),
      );
      return apiResponse.data;
    } on CodedServerException catch (e) {
      if (e.errorCode == 'USER_NOT_FOUND') {
        AppLogger.warning(
          'Basic user not found id=$id message="${e.message}"',
          tag: 'PROFILE',
        );
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<OwnerImageModel>> getProfileImages() async {
    final response = await _apiConsumer.get(EndPoints.profileImages);
    final apiResponse = ApiResponse<List<OwnerImageModel>>.fromJson(
      response as Map<String, dynamic>,
      (json) => (json as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(OwnerImageModel.fromJson)
          .toList(growable: false),
    );
    return apiResponse.data ?? const <OwnerImageModel>[];
  }

  @override
  Future<void> addProfileImages(List<File> images) async {
    // Pre-flight token check. Uploads carry megabytes, so a missing or
    // expired token is caught before the body is ever sent rather than
    // after the server rejects it.
    final token = await _secureStorage.get<String>(StorageKeys.token);
    if (token == null || token.isEmpty) {
      throw AuthException(message: LocaleKeys.errors_unauthorized_access);
    }

    try {
      await _apiConsumer.postMultipart(
        EndPoints.profileImages,
        files: images,
        fieldName: 'images',
      );
    } on ServerException catch (e) {
      // The user just tapped upload, so a server-side failure is more
      // useful phrased as "couldn't upload your photos" than as a generic
      // server error. Offline and timeout keep their own specific keys,
      // which HttpConsumer already assigns.
      final isServerFault =
          (e.statusCode != null && e.statusCode! >= 500) ||
          e.message == LocaleKeys.errors_server;
      if (isServerFault) {
        AppLogger.error('Photo upload server fault', tag: 'PROFILE');
        throw ServerException(
          message: LocaleKeys.errors_upload_failed,
          statusCode: e.statusCode,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteProfileImage(String imageId) async {
    await _apiConsumer.delete(EndPoints.profileImage(imageId));
  }

  @override
  Future<void> setMainProfileImage(String imageId) async {
    await _apiConsumer.put(EndPoints.setMainProfileImage(imageId));
  }

  @override
  Future<void> deleteAccount() async {
    AppLogger.debug('DELETE ACCOUNT', tag: 'PROFILE');
    // No body. `delete()` enforces the status envelope, so a non-success
    // throws a ServerException the repository maps to a Failure.
    await _apiConsumer.delete(EndPoints.deleteProfile);
    AppLogger.info('Account deleted', tag: 'PROFILE');
  }
}
