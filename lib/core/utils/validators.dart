import 'package:qeran/core/extensions/localization_extension.dart';

class Validators {
  static final RegExp emailPattern =
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  static final RegExp passwordPattern =
      RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z\d]).{8,}$');

  static String? validateEmail(String? val) {
    if (val == null || val.isEmpty) return 'validators.field_required'.t;
    if (!emailPattern.hasMatch(val)) return 'validators.invalid_email'.t;
    return null;
  }

  static String? validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'validators.field_required'.t;
    if (val.length < 8) return 'validators.password_too_short'.t;
    if (!passwordPattern.hasMatch(val)) return 'validators.password_weak'.t;
    return null;
  }
}
