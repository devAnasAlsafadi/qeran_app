import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_flag.dart';
import 'package:qeran/features/community/presentation/widgets/comments/comment_flag_panel.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';

import '../../../../../core/shipped_strings_rig.dart';

/// The flag line in B1 forms (E1): the count, then the reason reported most.
void main() {
  setUpAll(initShippedStrings);

  Future<List<String>> lines(
    WidgetTester tester,
    String language,
    List<CommunityFlag> flags,
  ) async {
    await pumpShippedStrings(
      tester,
      Locale(language),
      child: Column(
        children: [for (final flag in flags) CommentFlagLine(flag: flag)],
      ),
    );
    return [
      for (final text in tester.widgetList<Text>(find.byType(Text))) text.data!,
    ];
  }

  List<CommunityFlag> counted(List<int> counts) => [
    for (final n in counts)
      CommunityFlag(id: n, reportCount: n, topReason: ReportReason.spam),
  ];

  testWidgets('[ar] 1 / 2 / 3 / 11 / 100 reports', (tester) async {
    expect(await lines(tester, 'ar', counted([1, 2, 3, 11, 100])), [
      'تم الإبلاغ · بلاغ واحد · إزعاج أو إعلانات',
      'تم الإبلاغ · بلاغان · إزعاج أو إعلانات',
      'تم الإبلاغ · 3 بلاغات · إزعاج أو إعلانات',
      'تم الإبلاغ · 11 بلاغاً · إزعاج أو إعلانات',
      'تم الإبلاغ · 100 بلاغ · إزعاج أو إعلانات',
    ]);
  });

  testWidgets('[en] 1 / 2 / 100 reports', (tester) async {
    expect(await lines(tester, 'en', counted([1, 2, 100])), [
      'Reported · 1 report · Spam or advertising',
      'Reported · 2 reports · Spam or advertising',
      'Reported · 100 reports · Spam or advertising',
    ]);
  });

  testWidgets('a reason this build doesn\'t know: the count alone (S18); '
      'Other reads as on content', (tester) async {
    expect(
      await lines(tester, 'ar', const [
        CommunityFlag(id: 1, reportCount: 2),
        CommunityFlag(id: 2, reportCount: 1, topReason: ReportReason.other),
      ]),
      ['تم الإبلاغ · بلاغان', 'تم الإبلاغ · بلاغ واحد · سبب آخر'],
    );
  });
}
