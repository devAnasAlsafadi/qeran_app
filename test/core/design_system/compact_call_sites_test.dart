import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_premium_banner.dart';
import 'package:qeran/features/matchmaker/shared/presentation/widgets/matchmaker_card_action_bar.dart';
import 'package:qeran/features/profile/presentation/widgets/default_name_banner.dart';

import '../shipped_strings_rig.dart';

/// D1: the buttons that were `xs` (40 pt) or `sm` (36 pt) are `compact` now —
/// a real 48 pt tap target — and still fit a 360-wide phone in both
/// languages. The rest of D1's call sites are covered by their own screen
/// tests, and by `QeranButtonSize` having no size under 46 left to pick.
void main() {
  setUpAll(initShippedStrings);

  final sites = <String, Widget>{
    'her card action bar (Explore, Users)': MatchmakerCardActionBar(
      primary: MatchmakerPrimaryAction(
        label: 'مشاركة الملف مع مستخدم',
        icon: Icons.share_rounded,
        onTap: () {},
      ),
      secondaries: [
        MatchmakerSecondaryAction(icon: Icons.chat_rounded, onTap: () {}),
      ],
    ),
    'the default-name banner (Profile)': DefaultNameBanner(
      currentName: 'مستخدم',
      onEdit: () {},
      onDismiss: () {},
    ),
    'the premium banner': QeranPremiumBanner(
      title: 'Qeran Premium',
      subtitle: 'Unlock all of Qeran',
      ctaLabel: 'See plans',
      onCta: () {},
    ),
  };

  for (final MapEntry(key: name, value: site) in sites.entries) {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      testWidgets('$name: 48 pt at 360 wide [${locale.languageCode}]', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await pumpShippedStrings(
          tester,
          locale,
          child: Padding(padding: const EdgeInsets.all(16), child: site),
        );

        expect(tester.takeException(), isNull);
        for (final button in tester.widgetList(find.byType(QeranButton))) {
          expect(
            tester.getSize(find.byWidget(button)).height,
            48,
            reason: (button as QeranButton).label,
          );
        }
        expect(find.byType(QeranButton), findsWidgets);
      });
    }
  }
}
