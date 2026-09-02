import 'package:qeran/generated/locale_keys.g.dart';

import 'error_codes.dart';

/// `errorCode` → locale key maps for the auth endpoints, passed to
/// `serverFailureKey`. They live here rather than in the data source so
/// classifying another call adds a map entry, not another 500-line file.
///
/// Only codes the backend actually sends belong here. An unmapped code is not
/// a gap to paper over with a guess — it degrades to `errors.generic`, which
/// is localized and correct, just less specific.
class AuthFailureKeys {
  AuthFailureKeys._();

  /// `POST Auth/login`.
  static const Map<String, String> login = {
    AuthErrorCodes.invalidCredentials: LocaleKeys.errors_invalid_credentials,
    AuthErrorCodes.accountDeactivated: LocaleKeys.errors_account_deactivated,
    AuthErrorCodes.validationError: LocaleKeys.errors_bad_request,
  };
}
