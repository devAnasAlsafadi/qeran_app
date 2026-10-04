import 'package:qeran/core/di/injection_container.dart';

import '../data/datasources/report_remote_datasource.dart';
import '../data/repositories/report_repository_impl.dart';
import '../domain/entities/report_target.dart';
import '../domain/repositories/content_reporter.dart';
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
  // One cubit per report sheet, for its target.
  sl.registerFactoryParam<ReportCubit, ReportTarget, void>(
    (target, _) => ReportCubit(send: reportCallFor(target)),
  );
}

/// Where a report on [target] goes: a profile through this feature's
/// `POST reports`; Community content through Community's [ContentReporter]
/// (Q3), never this feature's datasource.
ReportCall reportCallFor(ReportTarget target) => switch (target) {
  UserReportTarget(:final userId) =>
    (reason, note) => sl<SubmitReportUseCase>()(
      targetUserId: userId,
      reason: reason,
      note: note,
    ),
  final ContentReportTarget content =>
    (reason, note) =>
        sl<ContentReporter>().report(content, reason: reason, note: note),
};
