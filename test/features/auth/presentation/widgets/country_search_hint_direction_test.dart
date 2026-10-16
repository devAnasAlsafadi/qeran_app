import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/auth/presentation/widgets/country_code_picker.dart';

import '../../../../core/shipped_strings_rig.dart';

/// The country search hint reads in the app's language direction: English
/// left to right, Arabic right to left. It was pinned RTL, so English hints
/// sat on the right (cleanup audit `19`, run 11).
void main() {
  setUpAll(initShippedStrings);

  for (final lang in ['en', 'ar']) {
    testWidgets('$lang: the search hint follows the language', (tester) async {
      await pumpShippedStrings(
        tester,
        Locale(lang),
        child: CountryCodePicker(selectedCode: '+970', onChanged: (_) {}),
      );
      await tester.tap(find.byType(CountryCodePicker));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField).first);
      expect(field.decoration!.hintTextDirection, isNull);
      expect(
        Directionality.of(tester.element(find.byType(TextField).first)),
        lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      );
    });
  }
}
