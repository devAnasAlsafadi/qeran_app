import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
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

    return Row(
      children: [
        _Monogram(initial: hasName ? _initial(trimmed) : null),
        QeranSpacing.hs12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _salaamKey(clock.hour).t(context),
                style: QeranTypography.caption.copyWith(
                  color: QeranColors.goldDeep,
                  fontSize: 12,
                ),
              ),
              if (hasName) ...[
                const SizedBox(height: QeranSpacing.s2),
                Text(
                  trimmed,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: QeranTypography.headline.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (showDate) ...[
          QeranSpacing.hs12,
          _DateBlock(date: clock, locale: context.locale.languageCode),
        ],
      ],
    );
  }

  /// First grapheme of the name as the monogram initial.
  String _initial(String value) =>
      String.fromCharCodes(value.characters.first.runes).toUpperCase();

  String _salaamKey(int hour) {
    if (hour < 12) return LocaleKeys.matchmaker_dashboard_salaam_morning;
    if (hour < 17) return LocaleKeys.matchmaker_dashboard_salaam_afternoon;
    return LocaleKeys.matchmaker_dashboard_salaam_evening;
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({this.initial});

  /// The gold initial, or null for the neutral (unknown-name) fallback.
  final String? initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: QeranColors.wine,
        shape: BoxShape.circle,
        border: Border.all(color: QeranColors.gold, width: 2),
      ),
      // Locale-aware font (NOT the Montserrat numeric style) so an Arabic
      // initial renders with real glyphs instead of tofu.
      child: initial == null
          ? const Icon(Icons.person_outline, size: 24, color: QeranColors.gold)
          : Text(
              initial!,
              style: QeranTypography.title.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: QeranColors.gold,
              ),
            ),
    );
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
