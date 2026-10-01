import 'package:flutter/widgets.dart';

import '../../generated/locale_keys.g.dart';
import '../extensions/localization_extension.dart';

/// A count as a footer shows it (A17, B1). Under a thousand, as is
/// ("128"). From a thousand up, in thousands: one decimal place below a
/// hundred thousand, cut rather than rounded so a count never reads higher
/// than it is («1.2 ألف» / "1.2K" for 1,250 — and 1,999 is "1.9K", not
/// "2K"); whole thousands in their plural form («ألف», «ألفان»,
/// «3 آلاف», «11 ألفاً», «100 ألف» / "1K", "2K"…).
String formatCompactCount(int count, BuildContext context) {
  if (count < 1000) return '$count';
  final tenths = count ~/ 100;
  if (count < 100000 && tenths % 10 != 0) {
    // A fraction always takes the `other` form (CLDR). Not through the
    // package's plural: it tests Arabic's ranges on the raw value and
    // writes «3.5 آلاف», «12.3 ألفاً».
    return '${LocaleKeys.count_thousands}.other'.t(
      context,
      namedArgs: {'n': (tenths / 10).toStringAsFixed(1)},
    );
  }
  return LocaleKeys.count_thousands.tPlural(context, count ~/ 1000);
}
