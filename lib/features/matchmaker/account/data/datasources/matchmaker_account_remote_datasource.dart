import 'dart:io';

import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/errors/server_error_classifier.dart';
import 'package:qeran/core/session/session_token_renewal.dart';
import 'package:qeran/features/auth/data/auth_failure_keys.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../shared/data/json_parsers.dart';
import '../../../shared/data/matchmaker_envelope.dart';
import '../models/matchmaker_me_image_model.dart';
import '../models/matchmaker_me_model.dart';

abstract interface class MatchmakerAccountRemoteDataSource {
  /// `GET /matchmaker/me`.
  Future<MatchmakerMeModel> getMe();

  /// `PUT /matchmaker/me` — body `{name}` (≤100 chars). Returns nothing on
  /// success (`data:null`); errors surface as [CodedServerException].
  Future<void> updateName(String name);

  /// `POST /matchmaker/me/profile-photo` — multipart field `Images`. Returns
  /// the saved profile image (first item of the response list).
  Future<MatchmakerMeImageModel> uploadPhoto(File image);

  /// `POST /matchmaker/me/deactivate` (empty body). The JWT stays valid, so
  /// the caller clears the session locally on success.
  Future<void> deactivate();

  /// `DELETE /matchmaker/me/account` — PERMANENT account deletion. The caller
  /// runs the post-success cleanup (device unlink → local wipe → login).
  Future<void> deleteAccount();

  /// `POST /api/auth/change-password` — body
  /// `{oldPassword, newPassword, confirmNewPassword}` (the DTO requires all
  /// three; the UI's single new-password field feeds both new + confirm).
  /// Shared auth endpoint. A failure throws [CodedServerException] carrying a
  /// locale key (never the server's sentence) and the `errorCode` — a wrong
  /// current password is `INVALID_OLD_PASSWORD`. Success answers with the new
  /// token, returned here (null if the answer carries none); the old one is
  /// refused from then on.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class MatchmakerAccountRemoteDataSourceImpl
    implements MatchmakerAccountRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const MatchmakerAccountRemoteDataSourceImpl({
    required ApiConsumer apiConsumer,
  }) : _apiConsumer = apiConsumer;

  @override
  Future<MatchmakerMeModel> getMe() async {
    AppLogger.debug('MATCHMAKER — get me', tag: 'MATCHMAKER');
    final response = await _apiConsumer.get(EndPoints.matchmakerMe);
    // `get()` enforced the OUTER envelope; tolerate a future double-wrap.
    final data =
        unwrapInnerEnvelope((response as Map<String, dynamic>)['data']);
    if (data == null) {
      AppLogger.error('MATCHMAKER — me ok but data was null', tag: 'MATCHMAKER');
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return MatchmakerMeModel.fromJson(data);
  }

  @override
  Future<void> updateName(String name) async {
    AppLogger.debug('MATCHMAKER — update name', tag: 'MATCHMAKER');
    // `put()` enforces status==1; a failure throws CodedServerException
    // carrying VALIDATION_ERROR / USER_NOT_FOUND.
    await _apiConsumer.put(EndPoints.matchmakerMeUpdate, body: {'name': name});
  }

  @override
  Future<MatchmakerMeImageModel> uploadPhoto(File image) async {
    AppLogger.debug('MATCHMAKER — upload photo', tag: 'MATCHMAKER');
    final response = await _apiConsumer.postMultipart(
      EndPoints.matchmakerMeProfilePhoto,
      files: [image],
      fieldName: 'Images',
    );
    // Response `data` is a LIST of images — take the first.
    final images = parseMapList((response as Map<String, dynamic>)['data']);
    if (images.isEmpty) {
      AppLogger.error(
        'MATCHMAKER — upload photo ok but data was empty',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return MatchmakerMeImageModel.fromJson(images.first);
  }

  @override
  Future<void> deactivate() async {
    AppLogger.debug('MATCHMAKER — deactivate', tag: 'MATCHMAKER');
    await _apiConsumer.post(EndPoints.matchmakerMeDeactivate);
  }

  @override
  Future<void> deleteAccount() async {
    AppLogger.debug('MATCHMAKER — delete account', tag: 'MATCHMAKER');
    await _apiConsumer.delete(EndPoints.matchmakerMeDeleteAccount);
  }

  @override
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    AppLogger.debug('MATCHMAKER — change password', tag: 'MATCHMAKER');
    final dynamic response;
    try {
      response = await _apiConsumer.post(
        EndPoints.changePassword,
        body: {
          'oldPassword': currentPassword,
          'newPassword': newPassword,
          // No confirm field in the UI — the single new-password field is the
          // source of truth, so it satisfies the DTO's required confirm too.
          'confirmNewPassword': newPassword,
        },
      );
    } on ServerException catch (e) {
      // The member's map, for the member's endpoint: a wrong password reads
      // as it does for a member, and the server's sentence never reaches her.
      // The code goes on with the key; the cubit places the message by it.
      throw CodedServerException(
        message: serverFailureKey(
          e,
          codeKeys: AuthFailureKeys.changePassword,
          label: 'CHANGE PASSWORD',
          tag: 'MATCHMAKER',
        ),
        errorCode: e is CodedServerException ? e.errorCode : null,
      );
    }
    return renewedTokenIn(response);
  }
}
