import 'package:flutter/material.dart';

import '../../../../../core/design_system/effects/ring_motif.dart';
import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';

part 'matchmaker_attention_card_parts.dart';

/// A wine hero "needs attention" card — big gold count, white label, and a
/// gold action link. When the count is 0 it reads calm: the urgent pulse
/// hides and the action becomes a gold check + reassuring [zeroLabel].
/// Reconciles to the elevated/hero card treatment (gradient + [eHero]).
class MatchmakerAttentionCard extends StatelessWidget {
  const MatchmakerAttentionCard({
    super.key,
    required this.icon,
    required this.count,
    required this.label,
    required this.actionLabel,
    required this.zeroLabel,
    required this.onTap,
    this.pulse = true,
  });

  final IconData icon;
  final int count;
  final String label;

  /// Shown as the gold action link when [count] > 0.
  final String actionLabel;

  /// Shown (with a gold check) when [count] == 0 — the calm case.
  final String zeroLabel;

  final VoidCallback onTap;

  /// Toggles the urgent-dot halo (design tweak `attentionPulse`).
  final bool pulse;

  static const _hero = BoxDecoration(
    borderRadius: QeranRadii.panelR,
    boxShadow: QeranShadows.eHero,
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [QeranColors.wineLight, QeranColors.wine],
    ),
  );

  static final _rings = PositionedDirectional(
    top: -56,
    end: -56,
    child: RingMotif(color: QeranColors.gold, opacity: 0.13, size: 150),
  );

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: QeranRadii.panelR,
      child: InkWell(
        borderRadius: QeranRadii.panelR,
        onTap: onTap,
        splashColor: QeranColors.gold08,
        highlightColor: QeranColors.gold08,
        child: DecoratedBox(
          decoration: _hero,
          child: ClipRRect(
            borderRadius: QeranRadii.panelR,
            child: Stack(
              children: [
                _rings,
                Padding(
                  padding: const EdgeInsets.all(QeranSpacing.s16),
                  child: _CardBody(card: this),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
