import 'package:flutter/material.dart';

import '../../auth_form_memo.dart';

class RegisterController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final nameFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  final ValueNotifier<bool> acceptedPolicyNotifier = ValueNotifier<bool>(false);

  final AuthFormMemo _memo;

  /// See [LoginController] — the username and email survive the hop between
  /// the two auth screens; the password deliberately does not.
  RegisterController({AuthFormMemo? memo})
      : _memo = memo ?? resolveAuthFormMemo() {
    nameController.text = _memo.displayName;
    emailController.text = _memo.email;
    nameController.addListener(_rememberName);
    emailController.addListener(_rememberEmail);
  }

  void _rememberName() => _memo.rememberDisplayName(nameController.text);

  void _rememberEmail() => _memo.rememberEmail(emailController.text);

  bool get acceptedPolicy => acceptedPolicyNotifier.value;

  bool validate() => formKey.currentState?.validate() ?? false;

  /// Called once registration succeeds — nothing is left to carry over.
  void forgetForm() => _memo.clear();

  void togglePolicyAcceptance() {
    acceptedPolicyNotifier.value = !acceptedPolicyNotifier.value;
  }

  void dispose() {
    nameController.removeListener(_rememberName);
    emailController.removeListener(_rememberEmail);
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameFocus.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    acceptedPolicyNotifier.dispose();
  }
}
