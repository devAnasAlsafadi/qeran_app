import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_monogram.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';

/// Dashboard greeting — 48px monogram + a stacked name/salaam block, with an
/// optional trailing date block. The name is the hero (large, bold, wine) and
/// the time-of-day salaam sits beneath it as a small, muted subline. The name
/// comes from the cached session (zero fetch); a null/empty name falls back to
/// the salaam alone rendered as the hero line (no empty name slot), with a
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
    return Row(
      children: [
        QeranMonogram(name: trimmed.isNotEmpty ? trimmed : null),
        QeranSpacing.hs12,
        Expanded(
          child: _NameBlock(
            name: trimmed,
            greeting: _salaamKey(clock.hour).t(context),
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
}

/// The name as the hero line over a muted salaam (plain, no inline name); with
/// no name, the salaam itself is the hero line.
class _NameBlock extends StatelessWidget {
  const _NameBlock({required this.name, required this.greeting});

  /// Trimmed; empty when unknown.
  final String name;
  final String greeting;

  // The prominent, bold, wine-toned line (headline's default color is
  // inkStrong == wine): the name, or the salaam when no name is known.
  static final _heroStyle = QeranTypography.headline.copyWith(
    fontWeight: FontWeight.w800,
  );
  static final _salaamStyle = QeranTypography.subtitle.copyWith(
    color: QeranColors.inkMuted,
  );

  @override
  Widget build(BuildContext context) {
    final hero = Text(
      name.isEmpty ? greeting : name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: _heroStyle,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        hero,
        if (name.isNotEmpty) ...[
          QeranSpacing.vs4,
          Text(
            greeting,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _salaamStyle,
          ),
        ],
      ],
    );
  }
}

class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.date, required this.locale});

  final DateTime date;
  final String locale;

  static final _dayStyle = QeranTypography.numeric.copyWith(
    fontSize: 14,
    color: QeranColors.inkStrong,
  );
  static final _monthStyle = QeranTypography.label.copyWith(fontSize: 13);

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
            Text(day, style: _dayStyle),
            QeranSpacing.hs4,
            Text(month, style: _monthStyle),
          ],
        ),
      ],
    );
  }
}
