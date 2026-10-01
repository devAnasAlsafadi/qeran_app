import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../errors/server_error_classifier.dart';

extension LocalizationExtension on String {
  String t(BuildContext context, {Map<String, String>? namedArgs}) =>
      context.tr(this, namedArgs: namedArgs);

  /// The form of this plural key for [n] (B1), with `{n}` in it replaced by
  /// [n]. The key holds one form per category its language uses — Arabic
  /// zero / one / two / few (3–10) / many (11–99) / other (100+), English
  /// one / other — and a missing category falls back to `other`.
  ///
  /// Whole numbers only: the package tests Arabic's ranges on the raw value,
  /// so 3.5 would take the few form, where a fraction is always `other`.
  String tPlural(
    BuildContext context,
    int n, {
    Map<String, String>? namedArgs,
  }) => context.plural(this, n, name: 'n', namedArgs: namedArgs);

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
