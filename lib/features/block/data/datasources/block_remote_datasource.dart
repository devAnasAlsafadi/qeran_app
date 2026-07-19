import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';

import '../models/blocked_user_model.dart';

abstract interface class BlockRemoteDataSource {
  /// `POST /api/block {targetUserId}`. Enveloped — `HttpConsumer.post` throws a
  /// `CodedServerException` (with errorCode) on a status:0 rejection.
  Future<void> blockUser(String targetUserId);

  /// `DELETE /api/block/{targetUserId}`.
  Future<void> unblockUser(String targetUserId);

  /// `GET /api/block` — the blocked-users list.
  Future<List<BlockedUserModel>> getBlockedUsers();
}

class BlockRemoteDataSourceImpl implements BlockRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const BlockRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<void> blockUser(String targetUserId) async {
    AppLogger.debug('BLOCK — block $targetUserId', tag: 'BLOCK');
    await _apiConsumer.post(
      EndPoints.block,
      body: {'targetUserId': targetUserId},
    );
  }

  @override
  Future<void> unblockUser(String targetUserId) async {
    AppLogger.debug('BLOCK — unblock $targetUserId', tag: 'BLOCK');
    await _apiConsumer.delete(EndPoints.blockUser(targetUserId));
  }

  @override
  Future<List<BlockedUserModel>> getBlockedUsers() async {
    AppLogger.debug('BLOCK — list', tag: 'BLOCK');
    final response = await _apiConsumer.get(EndPoints.block);
    final apiResponse = ApiResponse<List<BlockedUserModel>>.fromJson(
      response as Map<String, dynamic>,
      (json) => (json as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BlockedUserModel.fromJson)
          .toList(growable: false),
    );
    return apiResponse.data ?? const [];
  }
}
