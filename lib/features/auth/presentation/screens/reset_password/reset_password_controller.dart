import 'package:flutter/material.dart';

class ResetPasswordController {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final passwordFocus = FocusNode();
  final confirmFocus = FocusNode();

  bool validate() => formKey.currentState?.validate() ?? false;

  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    passwordFocus.dispose();
    confirmFocus.dispose();
  }
}
