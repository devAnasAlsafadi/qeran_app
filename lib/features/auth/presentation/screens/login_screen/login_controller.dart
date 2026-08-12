import 'package:flutter/material.dart';

import '../../auth_email_memo.dart';

class LoginController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final emailFocus = FocusNode();
  final passwordFocus = FocusNode();

  final AuthEmailMemo _emailMemo;

  /// [emailMemo] defaults to the app-scoped instance. A widget test that does
  /// not boot the container gets an isolated one instead of a crash — and
  /// isolation is what a test wants anyway.
  LoginController({AuthEmailMemo? emailMemo})
      : _emailMemo = emailMemo ?? resolveAuthEmailMemo() {
    // Seed from whatever was typed on the register screen before coming here.
    emailController.text = _emailMemo.email;
    // Live write-back: the other screen is built fresh on navigation, so the
    // value has to be in the memo BEFORE this one is disposed (a push does not
    // dispose the screen underneath at all).
    emailController.addListener(_rememberEmail);
  }

  void _rememberEmail() => _emailMemo.remember(emailController.text);

  bool validate() => formKey.currentState?.validate() ?? false;

  /// Called once authentication succeeds — nothing is left to carry over.
  void forgetEmail() => _emailMemo.clear();

  void dispose() {
    emailController.removeListener(_rememberEmail);
    emailController.dispose();
    passwordController.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
  }
}
