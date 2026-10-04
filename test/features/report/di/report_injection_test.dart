import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/report/di/report_injection.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';
import 'package:qeran/features/report/domain/repositories/content_reporter.dart';
import 'package:qeran/features/report/presentation/blocs/report_cubit.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

class _FakeReporter implements ContentReporter {
  final calls = <(ContentReportTarget, ReportReason, String?)>[];

  @override
  Future<Either<Failure, void>> report(
    ContentReportTarget target, {
    required ReportReason reason,
    String? note,
  }) async {
    calls.add((target, reason, note));
    return const Right(null);
  }
}

/// Q3: a report on content goes through Community — whose dev-flag mock
/// answers in memory — and never through the report feature's own
/// `POST reports`, so a made-up id can't reach the real endpoint.
void main() {
  late _MockApiConsumer api;
  late _FakeReporter community;

  setUp(() {
    api = _MockApiConsumer();
    community = _FakeReporter();
    sl.registerSingleton<ApiConsumer>(api);
    sl.registerSingleton<ContentReporter>(community);
    initReportDependencies();
    when(
      () => api.post(any(), body: any(named: 'body')),
    ).thenAnswer((_) async => {'status': 1, 'message': '', 'data': 'r-1'});
  });
  tearDown(sl.reset);

  test('content: through Community, never this feature\'s endpoint', () async {
    const target = ContentReportTarget(ReportContentKind.reply, 7);

    await sl<ReportCubit>(
      param1: target,
    ).submit(reason: ReportReason.spam, note: 'n');

    expect(community.calls, [(target, ReportReason.spam, 'n')]);
    verifyNever(() => api.post(any(), body: any(named: 'body')));
  });

  test('a profile: this feature\'s POST reports, as before', () async {
    await sl<ReportCubit>(
      param1: const UserReportTarget('u-1'),
    ).submit(reason: ReportReason.harassment);

    verify(
      () => api.post(
        'reports',
        body: {'targetUserId': 'u-1', 'reason': 'Harassment'},
      ),
    ).called(1);
    expect(community.calls, isEmpty);
  });
}
