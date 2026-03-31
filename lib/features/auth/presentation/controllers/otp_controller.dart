import 'package:flutter/material.dart';

class OtpController {
  final List<TextEditingController> otpControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> otpFocusNodes = List.generate(4, (_) => FocusNode());

  String get fullOtp => otpControllers.map((c) => c.text).join();

  bool get isOtpComplete => fullOtp.length == 4;

  void clearOtp() {
    for (var controller in otpControllers) {
      controller.clear();
    }
    if (otpFocusNodes.isNotEmpty) {
      otpFocusNodes[0].requestFocus();
    }
  }

  void dispose() {
    for (final c in otpControllers) {
      c.dispose();
    }
    for (final f in otpFocusNodes) {
      f.dispose();
    }
  }
}
