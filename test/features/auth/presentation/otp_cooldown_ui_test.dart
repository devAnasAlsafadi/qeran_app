import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/auth/presentation/blocs/whatsapp/whatsapp_state.dart';
import 'package:qeran/features/auth/presentation/screens/whatsapp_verification/widgets/otp_resend_row.dart';
import 'package:qeran/features/auth/presentation/widgets/whatsapp_failure_text.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../core/shipped_strings_rig.dart';

/// B2 on screen: the toast says how long to wait in its plural form, and the
/// resend row counts down from the server's seconds.
void main() {
  setUpAll(initShippedStrings);

  String cooldownText(BuildContext context, int seconds) => WhatsappFailure(
    LocaleKeys.errors_otp_cooldown,
    retryAfter: Duration(seconds: seconds),
  ).text(context);

  testWidgets('the wait in Arabic, in each plural form', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('ar'));

    expect(cooldownText(context, 1), 'انتظر ثانية واحدة قبل طلب رمز جديد.');
    expect(cooldownText(context, 2), 'انتظر ثانيتين قبل طلب رمز جديد.');
    expect(cooldownText(context, 3), 'انتظر 3 ثوانٍ قبل طلب رمز جديد.');
    expect(cooldownText(context, 42), 'انتظر 42 ثانية قبل طلب رمز جديد.');
    expect(cooldownText(context, 100), 'انتظر 100 ثانية قبل طلب رمز جديد.');
  });

  testWidgets('the wait in English, and no wait at all', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('en'));

    expect(
      cooldownText(context, 1),
      'Please wait 1 second before requesting a new code.',
    );
    expect(
      cooldownText(context, 42),
      'Please wait 42 seconds before requesting a new code.',
    );
    expect(
      WhatsappFailure(LocaleKeys.errors_otp_invalid).text(context),
      isNot(contains('wait')),
    );
  });

  Widget row(Duration? serverCooldown) => OtpResendRow(
    onResend: () {},
    isLoading: false,
    serverCooldown: serverCooldown,
  );

  testWidgets('the row counts down from the server\'s 42 seconds', (
    tester,
  ) async {
    await pumpShippedStrings(tester, const Locale('ar'), child: row(null));
    expect(find.text('إعادة إرسال'), findsOneWidget);

    await pumpShippedStrings(
      tester,
      const Locale('ar'),
      child: row(const Duration(seconds: 42)),
      settle: false,
    );
    expect(find.text('إعادة إرسال (42)'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('إعادة إرسال (41)'), findsOneWidget);

    await tester.pump(const Duration(seconds: 41));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('إعادة إرسال'), findsOneWidget);
  });
}
