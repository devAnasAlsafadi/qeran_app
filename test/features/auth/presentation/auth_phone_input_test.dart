import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/auth/presentation/widgets/auth_phone_input.dart';

import '../../../core/shipped_strings_rig.dart';

/// The phone field says its refusal in the reader's language.
///
/// `PhoneValidator` returns locale keys by contract, to be translated where
/// they're shown, and the field showed them untranslated: the client's
/// screenshots read "validators.phone_too_short" under the WhatsApp number.
void main() {
  setUpAll(initShippedStrings);

  final form = GlobalKey<FormState>();
  final controller = TextEditingController();
  final focus = FocusNode();
  final code = ValueNotifier('+970');
  tearDownAll(() {
    controller.dispose();
    focus.dispose();
    code.dispose();
  });

  Future<void> submit(WidgetTester tester, Locale locale, String typed) async {
    await pumpShippedStrings(
      tester,
      locale,
      child: Form(
        key: form,
        child: AuthPhoneInput(
          controller: controller,
          focusNode: focus,
          countryCodeNotifier: code,
        ),
      ),
    );
    controller.text = typed;
    form.currentState!.validate();
    await tester.pump();
  }

  const cases = {
    'ar': {
      '': 'رقم الهاتف مطلوب',
      '59x': 'رقم الهاتف يجب أن يحتوي على أرقام فقط',
      '123': 'رقم الهاتف قصير جداً',
    },
    'en': {
      '': 'Phone number is required',
      '59x': 'Phone number must contain digits only',
      '123': 'Phone number is too short',
    },
  };

  for (final MapEntry(key: lang, value: lines) in cases.entries) {
    for (final MapEntry(key: typed, value: line) in lines.entries) {
      testWidgets('$lang: «$typed» is refused in words, not a key', (
        tester,
      ) async {
        await submit(tester, Locale(lang), typed);
        expect(find.text(line), findsOneWidget);
        expect(find.textContaining('validators.'), findsNothing);
      });
    }
  }

  testWidgets('a valid number shows no refusal', (tester) async {
    await submit(tester, const Locale('ar'), '591234567');
    for (final line in cases['ar']!.values) {
      expect(find.text(line), findsNothing);
    }
    expect(find.textContaining('validators.'), findsNothing);
  });
}
