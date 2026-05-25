import 'package:easy_localization/easy_localization.dart';

class Validators {
  static final RegExp emailPattern = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  static final RegExp passwordPattern = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$',
  );

  // Validators are FormFieldValidator callbacks — no BuildContext is available.
  // Using the global tr() is intentional here: locale changes mid-form are
  // invisible until the user re-submits, which re-evaluates validators.
  static String? validateEmail(String? val) {
    if (val == null || val.isEmpty) return tr('validators.field_required');
    if (!emailPattern.hasMatch(val)) return tr('validators.invalid_email');
    return null;
  }

  static String? validatePassword(String? val) {
    if (val == null || val.isEmpty) return tr('validators.field_required');
    if (val.length < 8) return tr('validators.password_too_short');
    if (!passwordPattern.hasMatch(val)) return tr('validators.password_weak');
    return null;
  }
}
