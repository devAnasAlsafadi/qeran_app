import 'package:flutter/material.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../../discovery/domain/entities/discovery_filter_question.dart';
import '../../../../discovery/domain/entities/discovery_filter_selection.dart';
import '../../../../discovery/presentation/widgets/filter_expandable_shell.dart';

/// Date single-value filter leaf for explore `date` questions — Tariq's
/// contract treats date as an EXACT-match on `TextAnswer` in `yyyy-MM-dd`
/// form. A tap row inside the shared [FilterExpandableShell] opens a
/// design-system-themed [showDatePicker]; the emitted value is always ASCII
/// `yyyy-MM-dd` (manual padding — never the Arabic-Indic digits the locale's
/// formatter would produce, which the backend couldn't match). Empty clears
/// the filter. Discovery's range treatment of date is untouched (explore-only).
class MatchmakerExploreDateField extends StatelessWidget {
  final DiscoveryFilterQuestion question;
  final SingleValueSelection? selection;
  final ValueChanged<String> onChanged;

  const MatchmakerExploreDateField({
    super.key,
    required this.question,
    required this.selection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final value = selection?.value;
    final hasValue = value != null && value.isNotEmpty;
    return FilterExpandableShell(
      label: question.label,
      bodyBuilder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: QeranSpacing.s8),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: QeranRadii.controlR,
                  onTap: () => _pick(context, value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: QeranSpacing.s12,
                      vertical: QeranSpacing.s12,
                    ),
                    decoration: BoxDecoration(
                      color: QeranColors.paper,
                      borderRadius: QeranRadii.controlR,
                      border: Border.all(color: QeranColors.hairline),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            hasValue
                                ? value
                                : LocaleKeys.matchmaker_explore_filter_date_select
                                    .t(context),
                            textAlign: TextAlign.start,
                            style: QeranTypography.subtitle.copyWith(
                              color: hasValue
                                  ? QeranColors.inkBody
                                  : QeranColors.inkMuted,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: QeranColors.wine,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (hasValue)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: QeranColors.inkMuted,
                  onPressed: () => onChanged(''),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pick(BuildContext context, String? current) async {
    final now = DateTime.now();
    final initial = _parse(current) ?? DateTime(now.year - 25);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: QeranColors.wine,
                onPrimary: QeranColors.paper,
                surface: QeranColors.paper,
                onSurface: QeranColors.inkBody,
              ),
          datePickerTheme: const DatePickerThemeData(
            backgroundColor: QeranColors.paper,
            headerBackgroundColor: QeranColors.wine,
            headerForegroundColor: QeranColors.paper,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onChanged(_format(picked));
  }

  /// ASCII `yyyy-MM-dd` — manual padding so the value is never localized into
  /// Arabic-Indic numerals (the backend matches on the plain ISO string).
  String _format(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  DateTime? _parse(String? s) =>
      (s == null || s.isEmpty) ? null : DateTime.tryParse(s);
}
