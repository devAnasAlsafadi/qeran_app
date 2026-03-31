import 'package:flutter/material.dart';

class ResetPasswordController {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final passwordFocus = FocusNode();
  final confirmFocus = FocusNode();

  final ValueNotifier<bool> obscurePasswordNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> obscureConfirmNotifier = ValueNotifier<bool>(true);

  bool validate() => formKey.currentState?.validate() ?? false;

  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    passwordFocus.dispose();
    confirmFocus.dispose();
    obscurePasswordNotifier.dispose();
    obscureConfirmNotifier.dispose();
  }
}
