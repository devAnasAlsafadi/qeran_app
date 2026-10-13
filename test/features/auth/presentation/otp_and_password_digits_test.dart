import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/auth/presentation/controllers/otp_controller.dart';
import 'package:qeran/features/auth/presentation/screens/whatsapp_verification/widgets/otp_input_row.dart';
import 'package:qeran/features/auth/presentation/widgets/auth_password_field.dart';

import '../../../core/shipped_strings_rig.dart';

/// Run 7, item 6: a code typed in Arabic digits. The boxes filtered to ASCII
/// digits only, so «١» never appeared and focus never moved on. A password is
/// the opposite case: its digits are the user's own, and stay as typed.
void main() {
  setUpAll(initShippedStrings);

  late OtpController otp;
  setUp(() => otp = OtpController());
  tearDown(() => otp.dispose());

  Future<void> pumpBoxes(WidgetTester tester) => pumpShippedStrings(
    tester,
    const Locale('ar'),
    child: OtpInputRow(
      controllers: otp.otpControllers,
      focusNodes: otp.otpFocusNodes,
    ),
  );

  testWidgets('«١» in the first box shows 1 and moves on', (tester) async {
    await pumpBoxes(tester);
    await tester.enterText(find.byType(TextField).first, '١');
    await tester.pump();
    expect(otp.otpControllers.first.text, '1');
    expect(otp.otpFocusNodes[1].hasFocus, isTrue);
  });

  testWidgets('«۴» (Persian) in a box shows 4', (tester) async {
    await pumpBoxes(tester);
    await tester.enterText(find.byType(TextField).at(2), '۴');
    expect(otp.otpControllers[2].text, '4');
  });

  test('the code sent is ASCII, whatever reached the boxes', () {
    for (final (i, d) in ['١', '٢', '۳', '4'].indexed) {
      otp.otpControllers[i].text = d;
    }
    expect(otp.fullOtp, '1234');
    expect(otp.isOtpComplete, isTrue);
  });

  testWidgets('a password keeps the digits it was typed with', (tester) async {
    final controller = TextEditingController();
    final focus = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focus.dispose);
    await pumpShippedStrings(
      tester,
      const Locale('ar'),
      child: AuthPasswordField(controller: controller, focusNode: focus),
    );
    await tester.enterText(find.byType(TextField), 'Abc١٢٣!');
    expect(controller.text, 'Abc١٢٣!');
  });
}
