import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../shared/data/matchmaker_envelope.dart';
import '../models/case_note_model.dart';

abstract interface class CaseNoteRemoteDataSource {
  /// `null` when the case has no note yet (`data:null`, status:1 — not an
  /// error).
  Future<CaseNoteModel?> getNote(int caseId);

  /// Upserts (create / update) and returns the saved note.
  Future<CaseNoteModel> saveNote({
    required int caseId,
    required String content,
  });

  Future<void> deleteNote(int caseId);
}

class CaseNoteRemoteDataSourceImpl implements CaseNoteRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const CaseNoteRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<CaseNoteModel?> getNote(int caseId) async {
    AppLogger.debug('MATCHMAKER — get case note for $caseId', tag: 'MATCHMAKER');
    final response =
        await _apiConsumer.get(EndPoints.matchmakerCompatibilityCaseNote(caseId));
    // `get()` enforced the OUTER envelope (status == 1). The payload is the
    // plain single-wrapped `data` (the note object, or null when none). Route
    // it through unwrapInnerEnvelope defensively — a map with no `status` key
    // is returned as-is, so a future double-wrap would still parse unchanged.
    final data =
        unwrapInnerEnvelope((response as Map<String, dynamic>)['data']);
    return data == null ? null : CaseNoteModel.fromJson(data);
  }

  @override
  Future<CaseNoteModel> saveNote({
    required int caseId,
    required String content,
  }) async {
    AppLogger.debug('MATCHMAKER — save case note for $caseId', tag: 'MATCHMAKER');
    final response = await _apiConsumer.put(
      EndPoints.matchmakerCompatibilityCaseNote(caseId),
      body: {'content': content},
    );
    final data =
        unwrapInnerEnvelope((response as Map<String, dynamic>)['data']);
    if (data == null) {
      AppLogger.error(
        'MATCHMAKER — save case note ok but data was null',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return CaseNoteModel.fromJson(data);
  }

  @override
  Future<void> deleteNote(int caseId) async {
    AppLogger.debug(
      'MATCHMAKER — delete case note for $caseId',
      tag: 'MATCHMAKER',
    );
    // `delete()` enforces the status==1 envelope; `data:null` is success and
    // the call is idempotent (deleting a non-existent note still returns ok).
    await _apiConsumer.delete(EndPoints.matchmakerCompatibilityCaseNote(caseId));
  }
}
