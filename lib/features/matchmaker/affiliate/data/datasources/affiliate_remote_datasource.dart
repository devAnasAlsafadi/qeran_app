import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../shared/data/json_parsers.dart';
import '../models/affiliate_summary_model.dart';

abstract interface class AffiliateRemoteDataSource {
  /// `GET /affiliate/summary`. Read via `getRaw` so a 404 (matchmaker not
  /// enrolled) throws a [CodedServerException] carrying `statusCode == 404`,
  /// which the repository maps to the not-enrolled failure.
  Future<AffiliateSummaryModel> getSummary();
}

class AffiliateRemoteDataSourceImpl implements AffiliateRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const AffiliateRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<AffiliateSummaryModel> getSummary() async {
    AppLogger.debug('AFFILIATE — get summary', tag: 'AFFILIATE');
    final response = await _apiConsumer.getRaw(EndPoints.affiliateSummary);
    final map = parseNullableMap(response);
    if (map == null) {
      AppLogger.error('AFFILIATE — summary ok but body was not a map',
          tag: 'AFFILIATE');
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    // Tolerate either the bare payload or a `{status, data:{...}}` envelope.
    final data = parseNullableMap(map['data']) ?? map;
    return AffiliateSummaryModel.fromJson(data);
  }
}
