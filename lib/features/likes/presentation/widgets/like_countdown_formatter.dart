import 'package:flutter/widgets.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// One unit of the remaining time: its plural key and its count.
typedef CountdownPart = ({String key, int n});

/// Bucket-and-format helper for the remaining-time chip on the Likes
/// screen.
///
/// The bucketing is exposed as a pure function ([resolve]) so it's
/// unit-testable without spinning up EasyLocalization. The
/// presentation-side [format] says each unit in its plural form (Arabic
/// «يومان», «4 ساعات», «11 دقيقة») and joins two with `likes.time_left_pair`.
class LikeCountdownFormatter {
  const LikeCountdownFormatter._();

  /// Picks the largest non-zero unit and the one below it, so the chip stays
  /// compact. A zero second unit is left out («يوم», not «يوم و0 ساعة»).
  ///
  ///   * `≥ 24 h` → days (+ hours)
  ///   * `≥ 1 h`  → hours (+ minutes)
  ///   * `≥ 1 m`  → minutes
  ///   * `1..59 s` → [label] "soon", no parts
  ///   * `≤ 0`    → [label] "expired" (the status's own key), no parts
  static ({String? label, List<CountdownPart> parts}) resolve(int seconds) {
    if (seconds <= 0) {
      return (label: LocaleKeys.likes_status_expired, parts: const []);
    }
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    final days = hours ~/ 24;
    if (days > 0) {
      return _pair(
        (key: LocaleKeys.likes_countdown_days, n: days),
        (key: LocaleKeys.likes_countdown_hours, n: hours % 24),
      );
    }
    if (hours > 0) {
      return _pair(
        (key: LocaleKeys.likes_countdown_hours, n: hours),
        (key: LocaleKeys.likes_countdown_minutes, n: minutes % 60),
      );
    }
    if (minutes > 0) {
      return (
        label: null,
        parts: [(key: LocaleKeys.likes_countdown_minutes, n: minutes)],
      );
    }
    return (label: LocaleKeys.likes_time_left_soon, parts: const []);
  }

  static ({String? label, List<CountdownPart> parts}) _pair(
    CountdownPart first,
    CountdownPart second,
  ) => (label: null, parts: [first, if (second.n > 0) second]);

  static String format(BuildContext context, int seconds) {
    final r = resolve(seconds);
    final words = [for (final p in r.parts) p.key.tPlural(context, p.n)];
    if (words.isEmpty) return r.label!.t(context);
    if (words.length == 1) return words.single;
    return LocaleKeys.likes_time_left_pair.t(
      context,
      namedArgs: {'first': words.first, 'second': words.last},
    );
  }
}
