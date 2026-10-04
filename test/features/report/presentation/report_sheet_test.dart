import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';
import 'package:qeran/features/report/domain/entities/report_target.dart';
import 'package:qeran/features/report/presentation/blocs/report_cubit.dart';
import 'package:qeran/features/report/presentation/widgets/report_reason_row.dart';
import 'package:qeran/features/report/presentation/widgets/report_sheet.dart';

import '../../../core/shipped_strings_rig.dart';

/// The one report sheet (E5–E7): its title and reasons follow the target
/// (D30), the board's thanks for every report (Q7), and content that's gone
/// closes it with a notice.
void main() {
  setUpAll(initShippedStrings);

  final sent = <ReportReason>[];
  late Either<Failure, void> answer;

  setUp(() {
    sent.clear();
    answer = const Right(null);
    sl.registerFactoryParam<ReportCubit, ReportTarget, void>(
      (_, _) => ReportCubit(
        send: (reason, _) async {
          sent.add(reason);
          return answer;
        },
      ),
    );
  });
  tearDown(sl.reset);

  Future<void> open(
    WidgetTester tester,
    ReportTarget target, {
    Locale locale = const Locale('en'),
  }) async {
    addTearDown(AppSnackBar.debugReset);
    final context = await pumpShippedStrings(
      tester,
      locale,
      builder: (_, child) => AppSnackBarHost(child: child!),
    );
    showReportSheet(context, target: target);
    await tester.pumpAndSettle();
  }

  List<String> reasons(WidgetTester tester) => tester
      .widgetList<ReportReasonRow>(find.byType(ReportReasonRow))
      .map((r) => r.label)
      .toList();

  Future<void> send(WidgetTester tester, String reason, String cta) async {
    await tester.tap(find.text(reason));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(QeranButton, cta));
    await tester.pumpAndSettle();
  }

  /// Lets the toast run its course, so no timer outlives the test.
  Future<void> toastDone(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('a comment: its title and the five content reasons [en]', (
    tester,
  ) async {
    await open(tester, const ContentReportTarget(ReportContentKind.comment, 7));

    expect(find.text('Report comment'), findsOneWidget);
    expect(reasons(tester), [
      'Abuse or bullying',
      'Inappropriate content',
      'Sharing contact details',
      'Spam or advertising',
      'Something else',
    ]);
  });

  testWidgets('a reply and a post, in Arabic', (tester) async {
    await open(
      tester,
      const ContentReportTarget(ReportContentKind.reply, 7),
      locale: const Locale('ar'),
    );
    expect(find.text('الإبلاغ عن الرد'), findsOneWidget);
    expect(reasons(tester), [
      'إساءة أو تنمّر',
      'محتوى غير لائق',
      'مشاركة معلومات تواصل',
      'إزعاج أو إعلانات',
      'سبب آخر',
    ]);
  });

  testWidgets('a profile keeps its title and six reasons [ar]', (tester) async {
    await open(
      tester,
      const UserReportTarget('u-1'),
      locale: const Locale('ar'),
    );

    expect(find.text('إبلاغ'), findsOneWidget);
    expect(reasons(tester), hasLength(6));
    expect(reasons(tester), contains('تحرّش أو إساءة'));
  });

  testWidgets('sent: the sheet closes with the board\'s thanks (E6, Q7)', (
    tester,
  ) async {
    await open(tester, const ContentReportTarget(ReportContentKind.post, 1));

    await send(tester, 'Spam or advertising', 'Submit report');

    expect(sent, [ReportReason.spam]);
    expect(find.byType(ReportReasonRow), findsNothing);
    expect(
      find.text('Thank you. Your report was received and will be reviewed.'),
      findsOneWidget,
    );
    await toastDone(tester);
  });

  testWidgets('content gone: the sheet closes with the notice (E7) [ar]', (
    tester,
  ) async {
    answer = const Left(
      CodedServerFailure(message: 'x', errorCode: 'TARGET_CONTENT_NOT_FOUND'),
    );
    await open(
      tester,
      const ContentReportTarget(ReportContentKind.comment, 7),
      locale: const Locale('ar'),
    );

    await send(tester, 'سبب آخر', 'إرسال البلاغ');

    expect(find.byType(ReportReasonRow), findsNothing);
    expect(find.text('هذا المحتوى لم يعد متاحاً.'), findsOneWidget);
    await toastDone(tester);
  });

  testWidgets('another failure keeps the sheet open to try again', (
    tester,
  ) async {
    answer = const Left(OfflineFailure());
    await open(tester, const ContentReportTarget(ReportContentKind.comment, 7));

    await send(tester, 'Something else', 'Submit report');

    expect(find.byType(ReportReasonRow), findsNWidgets(5));
    await toastDone(tester);
  });
}
