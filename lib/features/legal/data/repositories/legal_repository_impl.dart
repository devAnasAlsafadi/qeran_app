import 'package:dartz/dartz.dart';
import 'package:qeran/core/data/repositories/base_repository.dart';
import 'package:qeran/core/errors/errors.dart';

import '../../domain/entities/legal_document.dart';
import '../../domain/entities/legal_document_type.dart';
import '../../domain/repositories/legal_repository.dart';
import '../datasources/legal_remote_datasource.dart';

class LegalRepositoryImpl with BaseRepository implements LegalRepository {
  final LegalRemoteDataSource _dataSource;

  const LegalRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, LegalDocument>> getDocument(LegalDocumentType type) =>
      executeApiCall(() async => (await _dataSource.getDocument(type)).toEntity());
}
