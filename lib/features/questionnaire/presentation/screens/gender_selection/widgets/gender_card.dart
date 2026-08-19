import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_assets.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// One identity card — a raised white panel holding the large gender
/// illustration with its label beneath. Unselected = white surface + a soft
/// hairline + subtle elevation so it reads as a distinct card on the cream
/// dome. Selected = the panel fills gold (`gold20`) with a darker gold-deep
/// border, a gold hero glow and a gold check badge.
class GenderCard extends StatelessWidget {
  final Gender gender;
  final bool isSelected;
  final VoidCallback onTap;

  const GenderCard({
    super.key,
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMale = gender == Gender.male;
    final String imageAsset =
        isMale ? AppAssets.genderMale : AppAssets.genderFemale;
    final String label = isMale
        ? LocaleKeys.questionnaire_gender_male.t(context)
        : LocaleKeys.questionnaire_gender_female.t(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: QeranMotion.standard,
        curve: QeranCurves.standard,
        decoration: BoxDecoration(
          // White by default (raised card on the cream dome), filling gold on
          // selection. AnimatedContainer tweens the colour for a smooth
          // white↔gold transition on tap.
          color: isSelected ? QeranColors.gold20 : QeranColors.paper,
          borderRadius: QeranRadii.cardR,
          border: Border.all(
            color: isSelected ? QeranColors.goldDeep : QeranColors.hairline,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? QeranShadows.eHero : QeranShadows.e1,
        ),
        child: AspectRatio(
          aspectRatio: 0.78,
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        QeranSpacing.s12,
                        QeranSpacing.s12,
                        QeranSpacing.s12,
                        QeranSpacing.s4,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // The two sources have different aspects (female
                          // 440×567 ≈ 0.776, male 388×642 ≈ 0.604). Render BOTH
                          // at the SAME height so the cards look balanced: cap
                          // the height so the WIDER (female) illustration still
                          // fits the box width — this guarantees equal height,
                          // a consistent laurel baseline, and no crop/distortion
                          // for either. Bottom-aligned + horizontally centered.
                          const widestAspect = 0.776; // female — the wider source
                          final maxByWidth = constraints.maxWidth / widestAspect;
                          final targetHeight = constraints.maxHeight < maxByWidth
                              ? constraints.maxHeight
                              : maxByWidth;
                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: _MirroredForLtr(
                              child: Image.asset(
                                imageAsset,
                                height: targetHeight,
                                fit: BoxFit.contain,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: QeranSpacing.s16),
                    child: Text(label, style: QeranTypography.title),
                  ),
                ],
              ),
              if (isSelected)
                const PositionedDirectional(
                  top: QeranSpacing.s8,
                  end: QeranSpacing.s8,
                  child: _SelectedBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flips [child] horizontally when the ambient direction is LTR.
///
/// The illustrations are drawn for ARABIC: the man faces left, the woman faces
/// right. With the man on the Row's start edge — the RIGHT in RTL — the two
/// look at each other. In LTR the start edge moves to the left, the cards swap
/// sides, and that same artwork points them both outward: backs turned. Mirror
/// the pixels and the composition survives the flip, with no second set of
/// assets to draw and keep in sync.
///
/// Deliberately NOT `Image.matchTextDirection`: that flag assumes assets are
/// authored for LTR and flips them for RTL, which is exactly inverted here. It
/// would break Arabic — the case that is correct today — and leave English
/// wrong. Using it would first require re-authoring both files mirrored.
///
/// RTL returns [child] untouched, so the primary locale renders exactly the
/// tree it always has.
class _MirroredForLtr extends StatelessWidget {
  const _MirroredForLtr({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Directionality.of(context) == TextDirection.rtl) return child;
    // The card tweens its background colour on selection, and that animation
    // repaints this subtree. Isolating the illustration keeps the transformed
    // layer off the tween's repaint path.
    return RepaintBoundary(
      child: Transform.scale(scaleX: -1, child: child),
    );
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: QeranColors.gold,
      ),
      child: const Icon(Icons.check_rounded, size: 15, color: QeranColors.wine),
    );
  }
}
