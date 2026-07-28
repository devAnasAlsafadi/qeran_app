import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Matches a translation key (`errors.invalid_credentials`) and nothing a
/// backend would ever send as prose — every segment is ASCII word chars and
/// there is at least one dot. Arabic/English sentences never match.
final RegExp _kLooksLikeKey = RegExp(r'^[A-Za-z0-9_]+(?:\.[A-Za-z0-9_]+)+$');

extension LocalizationExtension on String {
  String t(BuildContext context) => context.tr(this);

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
    return _kLooksLikeKey.hasMatch(value) ? value.t(context) : value;
  }
}
