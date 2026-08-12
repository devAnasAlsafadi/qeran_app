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

  /// Characters the backend rejects outright on the display name. Mirrored
  /// here so the user is told before a round trip, not after a 400.
  static final RegExp displayNameForbidden = RegExp(r'[<>%]');

  static const int displayNameMin = 2;
  static const int displayNameMax = 100;

  /// The name shown to other members. Rules match the backend's contract on
  /// `POST /Auth/register-new` and `PUT /api/profile`; the server stays the
  /// real gate, this is only to save the user a failed submit.
  static String? validateDisplayName(String? val) {
    final value = val?.trim() ?? '';
    if (value.isEmpty) return tr('validators.field_required');
    if (value.length < displayNameMin) return tr('validators.name_too_short');
    if (value.length > displayNameMax) return tr('validators.name_too_long');
    if (displayNameForbidden.hasMatch(value)) {
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
