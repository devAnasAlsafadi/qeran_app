import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/domain/entities/success_response.dart';

/// Data source for the signed-in user's password change. Hits the SHARED
/// `Auth/change-password` endpoint (the same one the matchmaker account
/// feature uses) — it authenticates via the JWT, so it works for any
/// signed-in user without a role-specific route.
abstract interface class ChangePasswordRemoteDataSource {
  /// `POST Auth/change-password` — body
  /// `{oldPassword, newPassword, confirmNewPassword}` (the DTO requires all
  /// three). A wrong current password comes back as a `status == 0` envelope,
  /// which the [ApiConsumer] surfaces as a `CodedServerException`; success
  /// returns `data: null`.
  Future<SuccessResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
}

class ChangePasswordRemoteDataSourceImpl
    implements ChangePasswordRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const ChangePasswordRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<SuccessResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    AppLogger.debug('AUTH — change password', tag: 'AUTH');
    final response = await _apiConsumer.post(
      EndPoints.changePassword,
      body: {
        'oldPassword': currentPassword,
        'newPassword': newPassword,
        'confirmNewPassword': confirmPassword,
      },
    );
    final apiResponse = ApiResponse<void>.fromJson(response, (_) {});
    return SuccessResponse.fromApiResponse(apiResponse);
  }
}
