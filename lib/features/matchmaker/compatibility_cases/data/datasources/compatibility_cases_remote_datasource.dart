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
}
