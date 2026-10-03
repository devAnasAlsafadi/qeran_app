import 'package:flutter/widgets.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/server_clock.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Shared relative-time formatters, backed by the neutral `time.*` locale
/// keys (so they carry no feature namespace). Input is an ISO-UTC
/// timestamp; a date falls back to the device's local time.
class QeranRelativeTime {
  const QeranRelativeTime._();

  /// Weeks are counted up to this many; anything older shows its date (Q6).
  static const int _maxWeeks = 4;

  /// Compact (now / Nm / Nh / Nd → short date) in both languages — the
  /// style the notification inboxes use.
  ///
  /// Returns `null` when [at] is null (callers omit the time line entirely
  /// in that case).
  static String? format(DateTime? at, BuildContext context) {
    if (at == null) return null;
    final local = at.toLocal();
    final diff = DateTime.now().difference(local);

    if (diff.inMinutes < 1) {
      return LocaleKeys.time_now.t(context);
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}${LocaleKeys.time_minute.t(context)}';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}${LocaleKeys.time_hour.t(context)}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}${LocaleKeys.time_day.t(context)}';
    }
    return _date(local);
  }

  /// How long ago [at] was, as the Community boards write it (Q6): «الآن» /
  /// "Just now" under a minute, then minutes and hours up to a day; from a
  /// day on, the days between the two local calendar dates («أمس» /
  /// "Yesterday" for one, so a post from the 1st never reads "Yesterday" on
  /// the 3rd) and weeks of them up to four, each in its plural form (B1);
  /// older than that, the date. Long by default ("2 hours ago", for cards).
  /// [compact] is for tight rows, where each language picks its own form:
  /// English shortens ("2h"), Arabic keeps the long one.
  ///
  /// [now] defaults to the server's clock, so a phone whose clock is off
  /// still calls something posted a moment ago "Just now".
  static String? ago(
    DateTime? at,
    BuildContext context, {
    bool compact = false,
    DateTime? now,
  }) {
    if (at == null) return null;
    final to = now ?? ServerClock.instance.now();
    final elapsed = to.difference(at);
    if (elapsed.inMinutes < 1) return LocaleKeys.time_just_now.t(context);
    final days = _calendarDays(at.toLocal(), to.toLocal());
    if (days ~/ 7 > _maxWeeks) return _date(at.toLocal());

    final (n, long, short) = unit(elapsed, days);
    return (compact ? short : long).tPlural(context, n);
  }

  /// The unit for [elapsed] whose local dates are [days] apart: the count,
  /// and its long and compact keys. Minutes, then hours while under a day —
  /// or still the same date, which a 25-hour day of a clock change allows —
  /// then calendar days, then weeks of them.
  @visibleForTesting
  static (int, String, String) unit(Duration elapsed, int days) {
    if (elapsed.inHours < 1) {
      return (
        elapsed.inMinutes,
        LocaleKeys.time_minutes_ago,
        LocaleKeys.time_minutes_ago_compact,
      );
    }
    if (elapsed.inDays < 1 || days < 1) {
      return (
        elapsed.inHours,
        LocaleKeys.time_hours_ago,
        LocaleKeys.time_hours_ago_compact,
      );
    }
    if (days < 7) {
      return (days, LocaleKeys.time_days_ago, LocaleKeys.time_days_ago_compact);
    }
    return (
      days ~/ 7,
      LocaleKeys.time_weeks_ago,
      LocaleKeys.time_weeks_ago_compact,
    );
  }

  /// Whole calendar days from [from]'s date to [to]'s, whatever the hours.
  /// Counted between UTC midnights, so a clock change's 23- or 25-hour day
  /// still counts as one.
  static int _calendarDays(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  /// `yyyy/mm/dd` of a local date.
  static String _date(DateTime local) {
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}/$m/$d';
  }
}
