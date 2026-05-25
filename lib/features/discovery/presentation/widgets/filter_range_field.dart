import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/discovery_filter_question.dart';
import '../../domain/entities/discovery_filter_selection.dart';
import '../../domain/entities/filter_question_type.dart';

/// Range slider for any question with `isRange == true`.
///
/// Unit precedence: backend [DiscoveryFilterQuestion.unit] → type-based
/// fallback (cm / kg / years). Min/max precedence: backend
/// [DiscoveryFilterQuestion.minValue]/[maxValue] → type defaults.
class FilterRangeField extends StatelessWidget {
  final DiscoveryFilterQuestion question;
  final RangeSelection? selection;
  final void Function(int min, int max) onChanged;

  const FilterRangeField({
    super.key,
    required this.question,
    required this.selection,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final lo = question.effectiveMin.toDouble();
    final hi = question.effectiveMax.toDouble();
    final current = RangeValues(
      (selection?.min ?? question.effectiveMin).toDouble().clamp(lo, hi),
      (selection?.max ?? question.effectiveMax).toDouble().clamp(lo, hi),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.p16,
        vertical: AppDimens.p12,
      ),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(AppDimens.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            question.label,
            textAlign: TextAlign.end,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.white,
              overlayColor: AppColors.primary.withValues(alpha: 0.12),
              rangeThumbShape: const RoundRangeSliderThumbShape(
                enabledThumbRadius: 10,
                pressedElevation: 2,
              ),
              showValueIndicator: ShowValueIndicator.never,
              trackHeight: 3,
            ),
            child: RangeSlider(
              values: current,
              min: lo,
              max: hi,
              divisions: (hi - lo).toInt().clamp(1, 1000),
              onChanged: (v) => onChanged(v.start.round(), v.end.round()),
            ),
          ),
          Text(
            LocaleKeys.discovery_filter_range_format.tr(
              namedArgs: {
                'label': question.label,
                'min': current.start.round().toString(),
                'max': current.end.round().toString(),
                'unit': _resolveUnit(context),
              },
            ),
            textAlign: TextAlign.end,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Backend unit takes precedence. Type-based fallback covers the
  /// case where the dashboard forgets the field (defensive).
  String _resolveUnit(BuildContext context) {
    final backend = question.unit;
    if (backend != null && backend.isNotEmpty) return backend;
    return switch (question.type) {
      FilterQuestionType.height => LocaleKeys.discovery_unit_cm.t(context),
      FilterQuestionType.weight => LocaleKeys.discovery_unit_kg.t(context),
      FilterQuestionType.date => LocaleKeys.discovery_unit_year.t(context),
      _ => '',
    };
  }
}
