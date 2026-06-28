import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/api_response.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/legal_document_type.dart';
import '../models/legal_document_model.dart';

abstract interface class LegalRemoteDataSource {
  /// Fetches one legal document. Both endpoints are public (no JWT required)
  /// and share the same envelope/shape.
  Future<LegalDocumentModel> getDocument(LegalDocumentType type);
}

class LegalRemoteDataSourceImpl implements LegalRemoteDataSource {
  final ApiConsumer _apiConsumer;

  const LegalRemoteDataSourceImpl({required ApiConsumer apiConsumer})
      : _apiConsumer = apiConsumer;

  @override
  Future<LegalDocumentModel> getDocument(LegalDocumentType type) async {
    final path = switch (type) {
      LegalDocumentType.termsAndConditions => EndPoints.termsAndConditions,
      LegalDocumentType.privacyPolicy => EndPoints.privacyPolicy,
    };
    AppLogger.debug('LEGAL — get ${type.name}', tag: 'LEGAL');
    final response = await _apiConsumer.get(path);
    final apiResponse = ApiResponse<LegalDocumentModel>.fromJson(
      response as Map<String, dynamic>,
      (json) => LegalDocumentModel.fromJson(json as Map<String, dynamic>),
    );
    final data = apiResponse.data;
    if (data == null) {
      AppLogger.error('LEGAL — ${type.name} ok but data null', tag: 'LEGAL');
      throw ServerException(message: LocaleKeys.errors_generic);
    }
    return data;
  }
}
