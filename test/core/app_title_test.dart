import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/qeran_app.dart';

import 'shipped_fonts_rig.dart';
import 'shipped_strings_rig.dart';

/// The task switcher shows the app's name in the member's language, not the
/// fixed "Qeran App" (cleanup audit `19`, run 11).
void main() {
  setUpAll(initShippedStrings);

  test('the name in each language', () {
    expect(shipped('ar', 'common.app_name'), 'قِران');
    expect(shipped('en', 'common.app_name'), 'Qeran');
  });

  for (final lang in ['ar', 'en']) {
    testWidgets('$lang: the app title', (tester) async {
      final context = await pumpShippedStrings(tester, Locale(lang));
      expect(qeranAppTitle(context), shipped(lang, 'common.app_name'));
    });
  }
}
