import 'dart:io';

import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
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
}
