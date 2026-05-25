import 'dart:io';

import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/domain/entities/success_response.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/generated/locale_keys.g.dart';

abstract interface class ProfileImageRemoteDataSource {
  /// Uploads images via multipart POST.
  ///
  /// The caller must ensure the primary image is at index 0.
  Future<SuccessResponse<dynamic>> uploadImages({required List<File> images});
}

class ProfileImageRemoteDataSourceImpl implements ProfileImageRemoteDataSource {
  final ApiConsumer _apiConsumer;
  final StorageService _secureStorage;

  ProfileImageRemoteDataSourceImpl({
    required ApiConsumer apiConsumer,
    required StorageService secureStorage,
  })  : _apiConsumer = apiConsumer,
        _secureStorage = secureStorage;

  /// Localized keys produced by `HttpConsumer` for transport-class errors
  /// (HTTP status code mapping + timeouts). These get re-mapped to the
  /// upload-specific copy `errors_upload_failed` to preserve pre-migration
  /// user-facing messages. Server-supplied error messages (Arabic copy
  /// from response bodies with `status==0`) pass through unchanged.
  static const _transportErrorKeys = <String>{
    LocaleKeys.errors_timeout,
    LocaleKeys.errors_server,
    LocaleKeys.errors_unauthorized,
    LocaleKeys.errors_forbidden,
    LocaleKeys.errors_not_found,
    LocaleKeys.errors_bad_request,
    LocaleKeys.errors_too_many_requests,
    LocaleKeys.errors_generic,
  };

  @override
  Future<SuccessResponse<dynamic>> uploadImages({
    required List<File> images,
  }) async {
    AppLogger.debug(
      'UPLOAD IMAGES -> count: ${images.length}',
      tag: 'PROFILE_IMAGE',
    );

    // Defensive token check — preserves the original AuthException with
    // `errors_unauthorized_access`. Without it, the request would fire
    // and the server would 401, which the consumer maps to the more
    // generic `errors_unauthorized` key.
    final token = await _secureStorage.get<String>(StorageKeys.token);
    if (token == null || token.isEmpty) {
      throw AuthException(message: LocaleKeys.errors_unauthorized_access);
    }

    try {
      final response = await _apiConsumer.postMultipart(
        EndPoints.profileImages,
        files: images,
        fieldName: 'images',
      );

      final apiResponse = ApiResponse<dynamic>.fromJson(
        response as Map<String, dynamic>,
        (data) => data,
      );

      AppLogger.info(
        'Images uploaded: ${apiResponse.message}',
        tag: 'PROFILE_IMAGE',
      );

      return SuccessResponse.fromApiResponse(apiResponse);
    } on ServerException catch (e) {
      AppLogger.error('Upload failed: ${e.message}', tag: 'PROFILE_IMAGE');
      if (_transportErrorKeys.contains(e.message)) {
        throw ServerException(message: LocaleKeys.errors_upload_failed);
      }
      rethrow;
    }
  }
}
