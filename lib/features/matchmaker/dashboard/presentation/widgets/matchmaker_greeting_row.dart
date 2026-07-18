import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_monogram.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Dashboard greeting — 48px monogram + time-of-day salaam + name, with
/// an optional trailing date block. The name comes from the cached session
/// (zero fetch); a null/empty name falls back to the salaam alone with a
/// neutral monogram. Numerals in the date stay LTR-tabular in both locales.
class MatchmakerGreetingRow extends StatelessWidget {
  const MatchmakerGreetingRow({
    super.key,
    required this.name,
    this.showDate = true,
    this.now,
  });

  /// The matchmaker's display name, or null/empty when unknown.
  final String? name;

  /// Whether the trailing weekday + day/month block is shown.
  final bool showDate;

  /// Injectable clock — defaults to [DateTime.now]. Kept for testability.
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final clock = now ?? DateTime.now();
    final trimmed = name?.trim() ?? '';
    final hasName = trimmed.isNotEmpty;

    // Backend-driven: with a name, the salaam is interpolated inline
    // ("صباح الخير، لارا" / "Good morning, Lara"); a null/empty name falls back
    // to the salaam alone (no trailing comma / empty slot).
    final greeting = hasName
        ? context.tr(
            _salaamNamedKey(clock.hour),
            namedArgs: {'name': trimmed},
          )
        : _salaamKey(clock.hour).t(context);

    return Row(
      children: [
        QeranMonogram(name: hasName ? trimmed : null),
        QeranSpacing.hs12,
        Expanded(
          child: Text(
            greeting,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: QeranTypography.headline.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (showDate) ...[
          QeranSpacing.hs12,
          _DateBlock(date: clock, locale: context.locale.languageCode),
        ],
      ],
    );
  }

  String _salaamKey(int hour) {
    if (hour < 12) return LocaleKeys.matchmaker_dashboard_salaam_morning;
    if (hour < 17) return LocaleKeys.matchmaker_dashboard_salaam_afternoon;
    return LocaleKeys.matchmaker_dashboard_salaam_evening;
  }

  String _salaamNamedKey(int hour) {
    if (hour < 12) return LocaleKeys.matchmaker_dashboard_salaam_morning_named;
    if (hour < 17) {
      return LocaleKeys.matchmaker_dashboard_salaam_afternoon_named;
    }
    return LocaleKeys.matchmaker_dashboard_salaam_evening_named;
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.date, required this.locale});

  final DateTime date;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final weekday = DateFormat('EEEE', locale).format(date);
    final month = DateFormat('MMM', locale).format(date);
    // The day number is forced Latin/tabular (Dart int → ASCII digits) so it
    // stays LTR even in Arabic, while the month name keeps the locale font.
    final day = date.day.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(weekday, style: QeranTypography.caption),
        const SizedBox(height: QeranSpacing.s2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              day,
              style: QeranTypography.numeric.copyWith(
                fontSize: 14,
                color: QeranColors.inkStrong,
              ),
            ),
            QeranSpacing.hs4,
            Text(
              month,
              style: QeranTypography.label.copyWith(fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }
}
