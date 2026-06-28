import 'package:qeran/core/di/injection_container.dart';

import '../data/datasources/legal_remote_datasource.dart';
import '../data/repositories/legal_repository_impl.dart';
import '../domain/repositories/legal_repository.dart';
import '../domain/usecases/get_legal_document_usecase.dart';

/// Legal documents — privacy-policy + terms-and-conditions. Both are public
/// endpoints sharing one shape; the usecase selects which via
/// [LegalDocumentType]. (P/T-2 adds the presentation cubit.)
void initLegalDependencies() {
  sl.registerLazySingleton<LegalRemoteDataSource>(
    () => LegalRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<LegalRepository>(
    () => LegalRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => GetLegalDocumentUseCase(sl()));
}
