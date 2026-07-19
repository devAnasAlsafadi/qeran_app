import 'package:qeran/core/di/injection_container.dart';

import '../data/datasources/report_remote_datasource.dart';
import '../data/repositories/report_repository_impl.dart';
import '../domain/repositories/report_repository.dart';
import '../domain/usecases/submit_report_usecase.dart';
import '../presentation/blocs/report_cubit.dart';

/// UGC safety — user/content reporting (`POST /api/reports`, JWT-gated).
void initReportDependencies() {
  sl.registerLazySingleton<ReportRemoteDataSource>(
    () => ReportRemoteDataSourceImpl(apiConsumer: sl()),
  );
  sl.registerLazySingleton<ReportRepository>(
    () => ReportRepositoryImpl(sl()),
  );
  sl.registerLazySingleton(() => SubmitReportUseCase(sl()));
  // One cubit per report sheet mount.
  sl.registerFactory(() => ReportCubit(submitReport: sl()));
}
