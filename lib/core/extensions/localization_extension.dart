import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../errors/server_error_classifier.dart';

extension LocalizationExtension on String {
  String t(BuildContext context, {Map<String, String>? namedArgs}) =>
      context.tr(this, namedArgs: namedArgs);

  /// Translates only when this string is a locale KEY; otherwise returns it
  /// verbatim.
  ///
  /// Use on any message that *may* have come from the server. Passing a raw
  /// backend string to [t] is a bug in two ways: it ships the server's own
  /// (often English) copy into an Arabic UI, and it silently defeats the
  /// "classify on errorCode, translate locally" contract. Data sources are
  /// expected to hand up keys — this is the safety net for the paths that
  /// still can't, not a licence to skip classification.
  String tOrRaw(BuildContext context) {
    final value = trim();
    if (value.isEmpty) return value;
    return kLocaleKeyShape.hasMatch(value) ? value.t(context) : value;
  }
}
