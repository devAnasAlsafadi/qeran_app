import 'package:flutter/material.dart';

import '../../auth_email_memo.dart';

class RegisterController {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final nameFocus = FocusNode();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  final ValueNotifier<bool> acceptedPolicyNotifier = ValueNotifier<bool>(false);

  final AuthEmailMemo _emailMemo;

  /// See [LoginController] — the email survives the hop between the two auth
  /// screens; the password deliberately does not.
  RegisterController({AuthEmailMemo? emailMemo})
      : _emailMemo = emailMemo ?? resolveAuthEmailMemo() {
    emailController.text = _emailMemo.email;
    emailController.addListener(_rememberEmail);
  }

  void _rememberEmail() => _emailMemo.remember(emailController.text);

  bool get acceptedPolicy => acceptedPolicyNotifier.value;

  bool validate() => formKey.currentState?.validate() ?? false;

  /// Called once registration succeeds — nothing is left to carry over.
  void forgetEmail() => _emailMemo.clear();

  void togglePolicyAcceptance() {
    acceptedPolicyNotifier.value = !acceptedPolicyNotifier.value;
  }

  void dispose() {
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
