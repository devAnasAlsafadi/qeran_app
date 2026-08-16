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

  /// The only characters the backend rejects on either name: C0/C1 control
  /// codes and DEL, newlines included. Everything else is accepted — any
  /// language, any script, any punctuation.
  static final RegExp nameForbidden = RegExp(r'[\x00-\x1F\x7F]');

  static const int displayNameMin = 2;
  static const int displayNameMax = 50;
  static const int realNameMax = 100;

  /// The name shown to other members. REQUIRED on every `PUT /api/profile`,
  /// and the same rules gate `POST /Auth/register-new`; the server stays the
  /// real gate, this is only to save the user a failed submit.
  static String? validateDisplayName(String? val) {
    final value = val?.trim() ?? '';
    if (value.isEmpty) return tr('validators.field_required');
    if (value.length < displayNameMin) return tr('validators.name_too_short');
    return _nameLimits(value, displayNameMax);
  }

  /// The legal name, collected for the formal-agreement stage. OPTIONAL —
  /// an empty field is valid and means "leave unchanged or clear", a
  /// distinction the caller draws against the loaded profile, not here.
  static String? validateRealName(String? val) {
    final value = val?.trim() ?? '';
    if (value.isEmpty) return null;
    return _nameLimits(value, realNameMax);
  }

  /// The two rules both names share, past their own required/optional gate.
  static String? _nameLimits(String value, int max) {
    if (value.length > max) {
      return tr('validators.name_too_long', namedArgs: {'max': '$max'});
    }
    if (nameForbidden.hasMatch(value)) {
      return tr('validators.name_invalid_chars');
    }
    return null;
  }

  static String? validatePassword(String? val) {
    if (val == null || val.isEmpty) return tr('validators.field_required');
    if (val.length < 8) return tr('validators.password_too_short');
    if (!passwordPattern.hasMatch(val)) return tr('validators.password_weak');
    return null;
  }
}
