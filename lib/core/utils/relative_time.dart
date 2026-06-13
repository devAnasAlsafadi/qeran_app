import 'package:flutter/widgets.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Shared compact relative-time formatter (now / Nm / Nh / Nd → short date).
///
/// Keeps one time format across the app — the same compact style the matchmaker
/// inbox uses — backed by the neutral `time.*` locale keys (so it carries no
/// feature namespace). Input is an ISO-UTC timestamp; output is rendered in the
/// device's local time.
class QeranRelativeTime {
  const QeranRelativeTime._();

  /// Returns the formatted relative time, or `null` when [at] is null (callers
  /// omit the time line entirely in that case).
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
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '${local.year}/$m/$d';
  }
}
