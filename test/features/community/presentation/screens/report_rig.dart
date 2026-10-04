import 'package:dartz/dartz.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/report/di/report_injection.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';
import 'package:qeran/features/report/domain/repositories/content_reporter.dart';
import 'package:qeran/features/report/presentation/blocs/report_cubit.dart';

/// Community's side of a content report: keeps what was reported and
/// answers [answer].
class FakeReporter implements ContentReporter {
  final reported = <ContentReportTarget>[];
  Either<Failure, void> answer = const Right(null);

  @override
  Future<Either<Failure, void>> report(
    ContentReportTarget target, {
    required ReportReason reason,
    String? note,
  }) async {
    reported.add(target);
    return answer;
  }
}

/// The report sheet as the app builds it, content reports going through
/// [reporter] (Q3).
void registerReporting(FakeReporter reporter) {
  sl.registerSingleton<ContentReporter>(reporter);
  sl.registerFactoryParam<ReportCubit, ReportTarget, void>(
    (target, _) => ReportCubit(send: reportCallFor(target)),
  );
}
