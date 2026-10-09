import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/account/presentation/widgets/referral_share_card.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/matchmaker_cases_filter.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/widgets/matchmaker_cases_filter_sheet.dart';
import 'package:qeran/features/matchmaker/shared/presentation/widgets/matchmaker_icon_action.dart';
import 'package:qeran/features/matchmaker/shared/presentation/widgets/matchmaker_segmented_tabs.dart';
import 'package:qeran/features/matchmaker/users/presentation/widgets/matchmaker_action_chip.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../core/shipped_strings_rig.dart';

/// D2 (Q10): her tappables that were under 48 pt — the icon action and the
/// contact chips (40 / ≈30), the segmented tabs (44), and three sheet rows —
/// are a real 48 pt now. The send button is pinned in `qeran_composer_test`.
void main() {
  setUpAll(initShippedStrings);

  Future<void> pumpAt360(
    WidgetTester tester,
    Locale locale,
    Widget child,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpShippedStrings(tester, locale, child: child);
    expect(tester.takeException(), isNull);
  }

  double heightOf(WidgetTester tester, Finder inside) => tester
      .getSize(find.ancestor(of: inside, matching: find.byType(InkWell)).first)
      .height;

  testWidgets('her icon action is a 48 pt disc', (tester) async {
    await pumpAt360(
      tester,
      const Locale('ar'),
      Center(
        child: MatchmakerIconAction(icon: Icons.chat_rounded, onTap: () {}),
      ),
    );

    expect(
      tester.getSize(find.byType(MatchmakerIconAction)),
      const Size.square(48),
    );
  });

  testWidgets('a contact chip is 48 pt tall', (tester) async {
    await pumpAt360(
      tester,
      const Locale('ar'),
      Center(
        child: MatchmakerActionChip(
          label: 'اتصال',
          icon: Icons.call_rounded,
          primary: false,
          loading: false,
          onTap: () {},
        ),
      ),
    );

    expect(heightOf(tester, find.text('اتصال')), 48);
  });

  for (final locale in const [Locale('ar'), Locale('en')]) {
    testWidgets(
      'every segment is 48 pt, at 360 wide [${locale.languageCode}]',
      (tester) async {
        await pumpAt360(
          tester,
          locale,
          MatchmakerSegmentedTabs(
            segments: const [
              MatchmakerSegment(
                labelKey: LocaleKeys.matchmaker_interests_tab_matches,
              ),
              MatchmakerSegment(
                labelKey: LocaleKeys.matchmaker_interests_tab_incoming,
              ),
              MatchmakerSegment(
                labelKey: LocaleKeys.matchmaker_interests_tab_outgoing,
              ),
            ],
            activeIndex: 0,
            onChanged: (_) {},
          ),
        );

        final cells = tester.widgetList(
          find.descendant(
            of: find.byType(MatchmakerSegmentedTabs),
            matching: find.byType(InkWell),
          ),
        );
        expect(cells, hasLength(3));
        for (final cell in cells) {
          expect(tester.getSize(find.byWidget(cell)).height, 48);
        }
      },
    );
  }

  testWidgets('the referral code box is at least 48 pt', (tester) async {
    await pumpAt360(
      tester,
      const Locale('ar'),
      const ReferralShareCard(code: 'QR-1234'),
    );

    expect(heightOf(tester, find.text('QR-1234')), greaterThanOrEqualTo(48));
  });

  testWidgets('every row of her cases filter is at least 48 pt', (
    tester,
  ) async {
    final context = await pumpShippedStrings(tester, const Locale('ar'));
    showMatchmakerCasesFilterSheet(
      context,
      current: const MatchmakerCasesFilter(),
    );
    await tester.pumpAndSettle();

    final rows = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byType(InkWell),
    );
    expect(rows, findsWidgets);
    for (final row in tester.widgetList(rows)) {
      final size = tester.getSize(find.byWidget(row));
      if (size.width > 200) {
        expect(size.height, greaterThanOrEqualTo(48));
      }
    }
  });
}
