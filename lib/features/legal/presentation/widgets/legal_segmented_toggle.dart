import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/tokens/qeran_motion.dart';
import '../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../domain/entities/legal_document_type.dart';

/// Two-segment toggle (الشروط | الخصوصية) — a paper card with a sliding gold
/// indicator that's RTL-correct via [AnimatedPositionedDirectional]. Same
/// visual idiom as the matchmaker segmented tabs, tokenised (no raw literals).
class LegalSegmentedToggle extends StatelessWidget {
  const LegalSegmentedToggle({
    super.key,
    required this.active,
    required this.onChanged,
  });

  final LegalDocumentType active;
  final ValueChanged<LegalDocumentType> onChanged;

  static const List<LegalDocumentType> _order = [
    LegalDocumentType.termsAndConditions,
    LegalDocumentType.privacyPolicy,
  ];
  static const _labels = [
    LocaleKeys.legal_tab_terms,
    LocaleKeys.legal_tab_privacy,
  ];

  static const Duration _dur = QeranMotion.standard;
  static const Curve _curve = QeranCurves.standard;
  static const double _barWidth = 40;
  static const double _cardHeight = 52;

  @override
  Widget build(BuildContext context) {
    final activeIndex = _order.indexOf(active);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        QeranSpacing.s20,
        QeranSpacing.s8,
        QeranSpacing.s20,
        QeranSpacing.s12,
      ),
      child: Container(
        height: _cardHeight,
        decoration: BoxDecoration(
          color: QeranColors.paper,
          borderRadius: QeranRadii.cardR,
          border: Border.all(color: QeranColors.wine08),
          boxShadow: QeranShadows.e2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(QeranSpacing.s4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth / _order.length;
              final barStart =
                  activeIndex * cellWidth + (cellWidth - _barWidth) / 2;
              return Stack(
                children: [
                  AnimatedPositionedDirectional(
                    duration: _dur,
                    curve: _curve,
                    start: barStart,
                    bottom: 6,
                    width: _barWidth,
                    height: 3,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: QeranColors.gold,
                        borderRadius: QeranRadii.pill,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < _order.length; i++)
                        Expanded(
                          child: _ToggleCell(
                            labelKey: _labels[i],
                            isActive: i == activeIndex,
                            onTap: () => onChanged(_order[i]),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ToggleCell extends StatelessWidget {
  const _ToggleCell({
    required this.labelKey,
    required this.isActive,
    required this.onTap,
  });

  final String labelKey;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: QeranRadii.controlR,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: LegalSegmentedToggle._dur,
          curve: LegalSegmentedToggle._curve,
          style: QeranTypography.subtitle.copyWith(
            fontSize: 14,
            color: isActive ? QeranColors.wine : QeranColors.inkMuted,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          ),
          child: Text(labelKey.t(context), maxLines: 1),
        ),
      ),
    );
  }
}
