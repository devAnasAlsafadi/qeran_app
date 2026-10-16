import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/widgets/language_switch_button.dart';

import '../shipped_fonts_rig.dart';
import '../shipped_strings_rig.dart';

/// The sign-in language button names itself in the member's language (screen
/// readers, long-press), not in fixed English (cleanup audit `19`, run 11).
void main() {
  setUpAll(initShippedStrings);

  for (final lang in ['ar', 'en']) {
    testWidgets('$lang: the tooltip', (tester) async {
      await pumpShippedStrings(
        tester,
        Locale(lang),
        child: const LanguageSwitchButton(),
      );

      final menu = tester.widget<PopupMenuButton<Locale>>(
        find.byType(PopupMenuButton<Locale>),
      );
      expect(menu.tooltip, shipped(lang, 'settings.language_row'));
    });
  }
}
