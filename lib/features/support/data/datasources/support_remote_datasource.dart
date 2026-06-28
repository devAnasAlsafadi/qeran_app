import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';

import '../json_parsers.dart';
import '../models/support_category_model.dart';

abstract interface class SupportRemoteDataSource {
  /// `GET /api/support/categories` — the problem-type list (JWT-gated).
  Future<List<SupportCategoryModel>> getCategories();

  /// `POST /api/support/tickets` — body `{categoryId, subject, details}`.
  /// `HttpConsumer.post` enforces the `status == 1` envelope and throws a
  /// `CodedServerException` (carrying `errorCode`) on a `status: 0` rejection.
  Future<void> createTicket({
    required int categoryId,
    required String subject,
    required String details,
  });
}

class SupportRemoteDataSourceImpl implements SupportRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const SupportRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<List<SupportCategoryModel>> getCategories() async {
    AppLogger.debug('SUPPORT — get categories', tag: 'SUPPORT');
    final response = await _apiConsumer.get(EndPoints.supportCategories);
    final apiResponse = ApiResponse<List<SupportCategoryModel>>.fromJson(
      response as Map<String, dynamic>,
      (json) => parseMapList(json)
          .map(SupportCategoryModel.fromJson)
          .toList(growable: false),
    );
    return apiResponse.data ?? const [];
  }

  @override
  Future<void> createTicket({
    required int categoryId,
    required String subject,
    required String details,
  }) async {
    AppLogger.debug('SUPPORT — create ticket (cat $categoryId)', tag: 'SUPPORT');
    await _apiConsumer.post(
      EndPoints.supportTickets,
      body: {
        'categoryId': categoryId,
        'subject': subject,
        'details': details,
      },
    );
  }
}
