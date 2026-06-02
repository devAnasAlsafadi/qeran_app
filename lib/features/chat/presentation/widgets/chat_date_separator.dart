import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Subtle inline date row inserted between message groups of
/// different calendar days. "Today", "Yesterday", weekday name, or
/// the locale-formatted long date.
class ChatDateSeparator extends StatelessWidget {
  final DateTime day;
  const ChatDateSeparator({super.key, required this.day});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: QeranSpacing.s12,
        horizontal: QeranSpacing.s16,
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s12,
            vertical: QeranSpacing.s4,
          ),
          decoration: const BoxDecoration(
            color: QeranColors.wine06,
            borderRadius: QeranRadii.pill,
          ),
          child: Text(
            _label(context, day),
            style: QeranTypography.caption,
          ),
        ),
      ),
    );
  }

  static String _label(BuildContext context, DateTime day) {
    final today = DateTime.now();
    final isSameDay = today.year == day.year &&
        today.month == day.month &&
        today.day == day.day;
    if (isSameDay) return LocaleKeys.chat_date_today.t(context);
    final yesterday = today.subtract(const Duration(days: 1));
    final isYesterday = yesterday.year == day.year &&
        yesterday.month == day.month &&
        yesterday.day == day.day;
    if (isYesterday) return LocaleKeys.chat_date_yesterday.t(context);
    final locale = context.locale.toString();
    try {
      return DateFormat.yMMMd(locale).format(day);
    } catch (_) {
      return '${day.year}-${day.month.toString().padLeft(2, '0')}-'
          '${day.day.toString().padLeft(2, '0')}';
    }
  }
}
