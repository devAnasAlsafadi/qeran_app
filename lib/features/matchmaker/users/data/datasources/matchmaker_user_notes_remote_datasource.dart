import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../shared/data/matchmaker_envelope.dart';
import '../models/matchmaker_user_note_model.dart';

abstract interface class MatchmakerUserNotesRemoteDataSource {
  /// `null` when the user has no note yet (`data:null`, status:1 — not an
  /// error).
  Future<MatchmakerUserNoteModel?> getNote(String userId);

  /// Upserts (create / update) and returns the saved note.
  Future<MatchmakerUserNoteModel> saveNote({
    required String userId,
    required String content,
  });

  Future<void> deleteNote(String userId);
}

class MatchmakerUserNotesRemoteDataSourceImpl
    implements MatchmakerUserNotesRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const MatchmakerUserNotesRemoteDataSourceImpl({
    required ApiConsumer apiConsumer,
  }) : _apiConsumer = apiConsumer;

  @override
  Future<MatchmakerUserNoteModel?> getNote(String userId) async {
    AppLogger.debug('MATCHMAKER — get note for $userId', tag: 'MATCHMAKER');
    final response =
        await _apiConsumer.get(EndPoints.matchmakerUserNote(userId));
    final data =
        unwrapInnerEnvelope((response as Map<String, dynamic>)['data']);
    return data == null ? null : MatchmakerUserNoteModel.fromJson(data);
  }

  @override
  Future<MatchmakerUserNoteModel> saveNote({
    required String userId,
    required String content,
  }) async {
    AppLogger.debug('MATCHMAKER — save note for $userId', tag: 'MATCHMAKER');
    final response = await _apiConsumer.put(
      EndPoints.matchmakerUserNote(userId),
      body: {'content': content},
    );
    final data =
        unwrapInnerEnvelope((response as Map<String, dynamic>)['data']);
    if (data == null) {
      AppLogger.error(
        'MATCHMAKER — save note ok but data was null',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return MatchmakerUserNoteModel.fromJson(data);
  }

  @override
  Future<void> deleteNote(String userId) async {
    AppLogger.debug('MATCHMAKER — delete note for $userId', tag: 'MATCHMAKER');
    // `delete()` enforces the status==1 envelope; `data:null` is success and
    // the call is idempotent (deleting a non-existent note still returns ok).
    await _apiConsumer.delete(EndPoints.matchmakerUserNote(userId));
  }
}
