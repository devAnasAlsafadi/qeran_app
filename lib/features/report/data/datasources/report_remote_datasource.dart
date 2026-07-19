import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';

import '../../domain/entities/report_reason.dart';

abstract interface class ReportRemoteDataSource {
  /// `POST /api/reports` — body `{targetUserId?, targetContentId?, reason,
  /// note?}`. `HttpConsumer.post` enforces the `status == 1` envelope and
  /// throws a `CodedServerException` (carrying `errorCode`) on a `status: 0`
  /// rejection. Returns the created reportId.
  Future<String> submitReport({
    String? targetUserId,
    String? targetContentId,
    required ReportReason reason,
    String? note,
  });
}

class ReportRemoteDataSourceImpl implements ReportRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const ReportRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<String> submitReport({
    String? targetUserId,
    String? targetContentId,
    required ReportReason reason,
    String? note,
  }) async {
    AppLogger.debug('REPORT — reason=${reason.apiValue}', tag: 'REPORT');
    final trimmedNote = note?.trim();
    final noteOrNull =
        (trimmedNote != null && trimmedNote.isNotEmpty) ? trimmedNote : null;
    final response = await _apiConsumer.post(
      EndPoints.reports,
      body: {
        'targetUserId': ?targetUserId,
        'targetContentId': ?targetContentId,
        'reason': reason.apiValue,
        'note': ?noteOrNull,
      },
    );
    final apiResponse = ApiResponse<String>.fromJson(
      response,
      (json) => json?.toString() ?? '',
    );
    return apiResponse.data ?? '';
  }
}
