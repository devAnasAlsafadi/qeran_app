import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/errors/server_error_classifier.dart';
import 'package:qeran/core/session/session_token_renewal.dart';

import '../auth_failure_keys.dart';

/// Data source for the signed-in user's password change. Hits the SHARED
/// `Auth/change-password` endpoint (the same one the matchmaker account
/// feature uses) — it authenticates via the JWT, so it works for any
/// signed-in user without a role-specific route.
abstract interface class ChangePasswordRemoteDataSource {
  /// `POST Auth/change-password` — body
  /// `{oldPassword, newPassword, confirmNewPassword}` (the DTO requires all
  /// three). A wrong current password comes back as a `status == 0` envelope,
  /// which the [ApiConsumer] surfaces as a `CodedServerException`. Success
  /// answers with the new token in `data`, as login does — the old one is
  /// refused from then on — returned here; null if the answer carries none.
  Future<String?> changePassword({
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
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    AppLogger.debug('AUTH — change password', tag: 'AUTH');
    final dynamic response;
    try {
      response = await _apiConsumer.post(
        EndPoints.changePassword,
        body: {
          'oldPassword': currentPassword,
          'newPassword': newPassword,
          'confirmNewPassword': confirmPassword,
        },
      );
    } on ServerException catch (e) {
      // Classified like the other seven auth calls, so `message` is always a
      // locale key. The errorCode is carried FORWARD rather than dropped:
      // `BaseRepository` preserves it on a `CodedServerFailure`, and the cubit
      // needs it to decide where the message belongs on screen.
      throw CodedServerException(
        message: serverFailureKey(
          e,
          codeKeys: AuthFailureKeys.changePassword,
          label: 'CHANGE PASSWORD',
          tag: 'AUTH',
        ),
        errorCode: e is CodedServerException ? e.errorCode : null,
      );
    }
    return renewedTokenIn(response);
  }
}
