import 'package:flutter/widgets.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/whatsapp/whatsapp_state.dart';

/// What a failed send or resend says, on the number screen and the code
/// screen alike.
extension WhatsappFailureText on WhatsappFailure {
  /// How long to wait, in its plural form, when the server said so (B2:
  /// «انتظر 42 ثانية قبل طلب رمز جديد.»); otherwise the classified message.
  String text(BuildContext context) => switch (retryAfter) {
    final Duration wait => LocaleKeys.errors_otp_cooldown_seconds.tPlural(
      context,
      wait.inSeconds,
    ),
    null => message.tOrRaw(context),
  };
}
