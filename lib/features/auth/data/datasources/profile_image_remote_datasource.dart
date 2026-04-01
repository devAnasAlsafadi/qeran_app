import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/domain/entities/success_response.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/storage_service.dart';

abstract interface class ProfileImageRemoteDataSource {
  Future<SuccessResponse<dynamic>> uploadImages({required List<File> images});
}

class ProfileImageRemoteDataSourceImpl implements ProfileImageRemoteDataSource {
  final http.Client _httpClient;
  final StorageService _secureStorage;

  ProfileImageRemoteDataSourceImpl({
    required http.Client httpClient,
    required StorageService secureStorage,
  })  : _httpClient = httpClient,
        _secureStorage = secureStorage;

  @override
  Future<SuccessResponse<dynamic>> uploadImages({
    required List<File> images,
  }) async {
    AppLogger.debug(
      'UPLOAD IMAGES -> count: ${images.length}',
      tag: 'PROFILE_IMAGE',
    );

    try {
      final token = await _secureStorage.get<String>('token');
      if (token == null || token.isEmpty) {
        throw AuthException(message: 'Token not found');
      }

      final uri = Uri.parse('${EndPoints.baseUrl}${EndPoints.profileImages}');
      final request = http.MultipartRequest('POST', uri);

      // Add auth header
      request.headers['Authorization'] = 'Bearer $token';

      // Attach files — primary image (user-selected) is at index 0
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();

        final multipartFile = http.MultipartFile(
          'images',
          stream,
          length,
          filename: 'image_$i.jpg',
        );

        request.files.add(multipartFile);
      }

      AppLogger.debug(
        'Sending multipart request to ${uri.toString()}',
        tag: 'PROFILE_IMAGE',
      );

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      AppLogger.debug(
        'Upload response: status=${response.statusCode}',
        tag: 'PROFILE_IMAGE',
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        AppLogger.error(
          'Upload failed: ${response.body}',
          tag: 'PROFILE_IMAGE',
        );
        throw ServerException(message: 'Upload failed');
      }

      // Parse response using ApiResponse wrapper
      final Map<String, dynamic> responseBody;
      try {
        responseBody = await Future.value(response.body);
      } catch (e) {
        throw ServerException(message: 'Invalid response format');
      }

      // The backend returns standard ApiResponse format
      final apiResponse = ApiResponse<dynamic>.fromJson(
        response.body,
        (json) => json,
      );

      AppLogger.info(
        'Images uploaded successfully: ${apiResponse.message}',
        tag: 'PROFILE_IMAGE',
      );

      return SuccessResponse.fromApiResponse(apiResponse);
    } catch (e) {
      AppLogger.error('Upload images error', error: e, tag: 'PROFILE_IMAGE');
      rethrow;
    }
  }
}
