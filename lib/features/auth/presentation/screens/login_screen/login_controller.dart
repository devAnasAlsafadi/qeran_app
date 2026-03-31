import 'package:flutter/material.dart';

class LoginController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  final ValueNotifier<bool> obscurePasswordNotifier = ValueNotifier<bool>(true);

  bool validate() => formKey.currentState?.validate() ?? false;

  void togglePasswordVisibility() {
    obscurePasswordNotifier.value = !obscurePasswordNotifier.value;
  }

  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    obscurePasswordNotifier.dispose();
  }
}
