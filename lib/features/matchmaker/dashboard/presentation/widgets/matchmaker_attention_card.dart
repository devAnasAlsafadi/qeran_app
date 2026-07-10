import 'package:flutter/material.dart';

import '../../../../../core/design_system/effects/ring_motif.dart';
import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';

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

  @override
  Widget build(BuildContext context) {
    final urgent = count > 0;
    return Material(
      color: Colors.transparent,
      borderRadius: QeranRadii.panelR,
      child: InkWell(
        borderRadius: QeranRadii.panelR,
        onTap: onTap,
        splashColor: QeranColors.gold08,
        highlightColor: QeranColors.gold08,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            borderRadius: QeranRadii.panelR,
            boxShadow: QeranShadows.eHero,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [QeranColors.wineLight, QeranColors.wine],
            ),
          ),
          child: ClipRRect(
            borderRadius: QeranRadii.panelR,
            child: Stack(
              children: [
                PositionedDirectional(
                  top: -56,
                  end: -56,
                  child: RingMotif(
                    color: QeranColors.gold,
                    opacity: 0.13,
                    size: 150,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(QeranSpacing.s16),
                  // Sizes to content (no fixed height) so the number, label
                  // and affordance always fit — no bottom overflow, and it
                  // grows gracefully under large text scale.
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _IconChip(icon: icon),
                          const Spacer(),
                          if (urgent && pulse) const _UrgentDot(),
                        ],
                      ),
                      QeranSpacing.vs12,
                      Text(
                        '$count',
                        style: QeranTypography.numeric.copyWith(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: QeranColors.gold,
                        ),
                      ),
                      const SizedBox(height: QeranSpacing.s2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: QeranTypography.bodySm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: QeranColors.paper.withValues(alpha: 0.92),
                        ),
                      ),
                      QeranSpacing.vs8,
                      urgent
                          ? Text(
                              actionLabel,
                              style: QeranTypography.label.copyWith(
                                color: QeranColors.gold,
                              ),
                            )
                          : _ZeroPill(label: zeroLabel),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: QeranColors.gold18,
        borderRadius: QeranRadii.controlR,
      ),
      child: Icon(icon, size: 22, color: QeranColors.gold),
    );
  }
}

class _ZeroPill extends StatelessWidget {
  const _ZeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.task_alt_rounded, size: 16, color: QeranColors.gold),
        QeranSpacing.hs4,
        // Flexible + ellipsis so a long zero label (e.g. "لا مراجعات") can
        // never overflow the narrow 2-up hero width.
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: QeranTypography.label.copyWith(color: QeranColors.gold),
          ),
        ),
      ],
    );
  }
}

/// Small gold urgent dot with a slow breathing halo.
class _UrgentDot extends StatefulWidget {
  const _UrgentDot();

  @override
  State<_UrgentDot> createState() => _UrgentDotState();
}

class _UrgentDotState extends State<_UrgentDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _c.value;
            return Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 8 + 12 * t,
                  height: 8 + 12 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: QeranColors.gold.withValues(alpha: 0.28 * (1 - t)),
                  ),
                ),
                child!,
              ],
            );
          },
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: QeranColors.gold,
            ),
          ),
        ),
      ),
    );
  }
}
