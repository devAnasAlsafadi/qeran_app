import 'package:flutter/material.dart';

class RegisterController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final nameFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  final ValueNotifier<bool> obscurePasswordNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> acceptedPolicyNotifier = ValueNotifier<bool>(false);

  bool get acceptedPolicy => acceptedPolicyNotifier.value;

  bool validate() => formKey.currentState?.validate() ?? false;

  void togglePasswordVisibility() {
    obscurePasswordNotifier.value = !obscurePasswordNotifier.value;
  }

  void togglePolicyAcceptance() {
    acceptedPolicyNotifier.value = !acceptedPolicyNotifier.value;
  }

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    obscurePasswordNotifier.dispose();
    acceptedPolicyNotifier.dispose();
  }
}
