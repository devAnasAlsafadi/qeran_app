import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../shared/data/matchmaker_envelope.dart';
import '../models/compatibility_cases_page_model.dart';

abstract interface class CompatibilityCasesRemoteDataSource {
  Future<CompatibilityCasesPageModel> getCases({
    required int page,
    required int pageSize,
  });

  /// Updates a case's formal-request status. [newStatus] is the verbatim
  /// PascalCase wire value (e.g. `"ParentsVisited"`). Returns the success
  /// message the server places in `data`.
  Future<String> updateStatus({
    required int formalRequestId,
    required String newStatus,
  });
}

class CompatibilityCasesRemoteDataSourceImpl
    implements CompatibilityCasesRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const CompatibilityCasesRemoteDataSourceImpl({
    required ApiConsumer apiConsumer,
  }) : _apiConsumer = apiConsumer;

  @override
  Future<CompatibilityCasesPageModel> getCases({
    required int page,
    required int pageSize,
  }) async {
    AppLogger.debug(
      'MATCHMAKER — get compatibility cases page=$page size=$pageSize',
      tag: 'MATCHMAKER',
    );
    final response = await _apiConsumer.get(
      EndPoints.matchmakerCompatibilityCases,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    // `get()` enforced the OUTER envelope (status == 1). The list is
    // single-wrapped today, but route the payload through
    // unwrapInnerEnvelope so a future double-wrap parses unchanged — a map
    // with no `status` key is returned as-is.
    final pageJson =
        unwrapInnerEnvelope((response as Map<String, dynamic>)['data']);
    if (pageJson == null) {
      AppLogger.error(
        'MATCHMAKER — compatibility cases ok but data was null',
        tag: 'MATCHMAKER',
      );
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return CompatibilityCasesPageModel.fromJson(pageJson);
  }

  @override
  Future<String> updateStatus({
    required int formalRequestId,
    required String newStatus,
  }) async {
    AppLogger.debug(
      'MATCHMAKER — update case status fr=$formalRequestId → $newStatus',
      tag: 'MATCHMAKER',
    );
    // Mutation: the human result text is in `data` with an empty `message`,
    // so go through postRaw + mutationResultText (status == 1 = success).
    // A failure throws a CodedServerException carrying the errorCode (e.g.
    // INVALID_STATUS_TRANSITION) — the repository maps it.
    final response = await _apiConsumer.postRaw(
      EndPoints.matchmakerCompatibilityCaseStatus(formalRequestId),
      body: {'newStatus': newStatus},
    );
    return mutationResultText(response);
  }
}
