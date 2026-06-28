import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/legal_document.dart';
import '../entities/legal_document_type.dart';
import '../repositories/legal_repository.dart';

/// Fetches a single legal document (privacy policy or terms) by [type].
class GetLegalDocumentUseCase {
  final LegalRepository _repository;
  const GetLegalDocumentUseCase(this._repository);

  Future<Either<Failure, LegalDocument>> call(LegalDocumentType type) =>
      _repository.getDocument(type);
}
