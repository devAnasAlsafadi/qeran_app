import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';

import '../../domain/entities/subscription_features.dart';

/// Lists the four feature allowances the user unlocks with the
/// selected plan. Renders "غير محدود" for the unlimited sentinel —
/// never the raw `-1`.
class CheckoutFeaturesCard extends StatelessWidget {
  final SubscriptionFeatures features;
  const CheckoutFeaturesCard({super.key, required this.features});

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    return Container(
      padding: const EdgeInsets.all(QeranSpacing.s16),
      decoration: BoxDecoration(
        color: QeranColors.paper,
        borderRadius: QeranRadii.cardR,
        boxShadow: QeranShadows.e2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'ماذا ستحصل عليه',
            style: QeranTypography.subtitle.copyWith(
              color: QeranColors.wine,
            ),
          ),
          const SizedBox(height: QeranSpacing.s12),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: QeranSpacing.s8),
            _FeatureRow(text: rows[i]),
          ],
        ],
      ),
    );
  }

  List<String> _rows() {
    return <String>[
      _format(features.likesAllowed, 'إعجاب', 'إعجابات', 'شهرياً'),
      _format(
        features.seriousInterestsAllowed,
        'اهتمام جدي',
        'اهتمامات جدية',
        'شهرياً',
      ),
      _format(
        features.photoExchangesAllowed,
        'تبادل صور',
        'تبادلات صور',
        'شهرياً',
      ),
      _format(
        features.dailyProfileViewsAllowed,
        'مشاهدة ملف',
        'مشاهدات ملفات',
        'يومياً',
      ),
    ];
  }

  static String _format(int value, String singular, String plural, String period) {
    if (SubscriptionFeatures.isUnlimited(value)) {
      return '$plural غير محدودة';
    }
    final unit = value == 1 ? singular : plural;
    return '$value $unit $period';
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: QeranColors.gold,
          size: 18,
        ),
        const SizedBox(width: QeranSpacing.s8),
        Expanded(
          child: Text(
            text,
            style: QeranTypography.body.copyWith(color: QeranColors.wine),
          ),
        ),
      ],
    );
  }
}
