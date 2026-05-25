import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Bucket-and-format helper for the remaining-time chip on the Likes
/// screen.
///
/// The bucketing is exposed as a pure function ([resolve]) so it's
/// unit-testable without spinning up EasyLocalization. The
/// presentation-side [format] wraps it with `context.tr` and named
/// args.
class LikeCountdownFormatter {
  const LikeCountdownFormatter._();

  /// Picks the largest non-zero unit pair so the chip stays compact.
  /// Output is always one of the four `likes.time_left_*` keys (or
  /// `likes.status_expired` when the count has dropped to zero).
  ///
  /// Returns the chosen locale key + the named arguments the
  /// `time_left_*` templates expect. `expired` returns an empty arg
  /// map.
  ///
  ///   * `> 24 h` → days + hours
  ///   * `> 1 h`  → hours + minutes
  ///   * `> 1 m`  → minutes only
  ///   * `1..59 s` → "soon"
  ///   * `≤ 0`    → "expired"
  static ({String key, Map<String, String> args}) resolve(int seconds) {
    if (seconds <= 0) {
      return (key: LocaleKeys.likes_status_expired, args: const {});
    }
    final totalMinutes = seconds ~/ 60;
    final totalHours = totalMinutes ~/ 60;
    final days = totalHours ~/ 24;
    final hoursRemainder = totalHours % 24;
    final minutesRemainder = totalMinutes % 60;

    if (days > 0) {
      return (
        key: LocaleKeys.likes_time_left_days_hours,
        args: {'days': '$days', 'hours': '$hoursRemainder'},
      );
    }
    if (totalHours > 0) {
      return (
        key: LocaleKeys.likes_time_left_hours_minutes,
        args: {'hours': '$totalHours', 'minutes': '$minutesRemainder'},
      );
    }
    if (totalMinutes > 0) {
      return (
        key: LocaleKeys.likes_time_left_minutes,
        args: {'minutes': '$totalMinutes'},
      );
    }
    return (key: LocaleKeys.likes_time_left_soon, args: const {});
  }

  static String format(BuildContext context, int seconds) {
    final r = resolve(seconds);
    if (r.args.isEmpty) {
      return r.key.t(context);
    }
    return context.tr(r.key, namedArgs: r.args);
  }
}
