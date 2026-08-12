import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../models/photo_view_permission_model.dart';
import '../models/photo_view_session_model.dart';

abstract interface class PhotoViewRemoteDataSource {
  Future<PhotoViewPermissionModel> getPermission(String targetUserId);
  Future<PhotoViewSessionModel> beginView(int photoExchangeId);
}

class PhotoViewRemoteDataSourceImpl implements PhotoViewRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const PhotoViewRemoteDataSourceImpl({required ApiConsumer apiConsumer})
    : _apiConsumer = apiConsumer;

  @override
  Future<PhotoViewPermissionModel> getPermission(String targetUserId) async {
    final response = await _apiConsumer.get(
      EndPoints.photoExchangePermission(targetUserId),
    );
    return PhotoViewPermissionModel.fromJson(_dataMap(response));
  }

  @override
  Future<PhotoViewSessionModel> beginView(int photoExchangeId) async {
    final response = await _apiConsumer.post(
      EndPoints.photoExchangeView(photoExchangeId),
    );
    return PhotoViewSessionModel.fromJson(_dataMap(response));
  }

  Map<String, dynamic> _dataMap(Object? response) {
    if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
    }
    throw ServerException(message: LocaleKeys.errors_invalid_server_response);
  }
}
