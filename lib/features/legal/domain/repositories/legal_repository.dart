import 'package:dartz/dartz.dart';
import 'package:qeran/core/errors/errors.dart';

import '../entities/legal_document.dart';
import '../entities/legal_document_type.dart';

abstract interface class LegalRepository {
  Future<Either<Failure, LegalDocument>> getDocument(LegalDocumentType type);
}
