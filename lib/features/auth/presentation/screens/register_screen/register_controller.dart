import 'package:flutter/material.dart';

class RegisterController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final referralCodeController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final nameFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();
  final referralFocus = FocusNode();

  final ValueNotifier<bool> acceptedPolicyNotifier = ValueNotifier<bool>(false);

  bool get acceptedPolicy => acceptedPolicyNotifier.value;

  bool validate() => formKey.currentState?.validate() ?? false;

  void togglePolicyAcceptance() {
    acceptedPolicyNotifier.value = !acceptedPolicyNotifier.value;
  }

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    referralCodeController.dispose();
    nameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    referralFocus.dispose();
    acceptedPolicyNotifier.dispose();
  }
}
