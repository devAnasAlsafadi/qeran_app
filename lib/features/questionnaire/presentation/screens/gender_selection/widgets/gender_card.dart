import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_assets.dart';
import 'package:qeran/generated/locale_keys.g.dart';

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
    final String imageAsset = isMale ? AppAssets.male : AppAssets.female;
    final String label = isMale
        ? LocaleKeys.questionnaire_gender_male.t(context)
        : LocaleKeys.questionnaire_gender_female.t(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: QeranMotion.standard,
        curve: QeranCurves.standard,
        decoration: BoxDecoration(
          color: QeranColors.paper,
          borderRadius: QeranRadii.cardR,
          border: Border.all(
            color: isSelected ? QeranColors.wine : QeranColors.hairline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: AspectRatio(
          aspectRatio: 0.85,
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(QeranSpacing.s16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Avatar(imageAsset: imageAsset, isSelected: isSelected),
                      QeranSpacing.vs12,
                      Text(label, style: QeranTypography.title),
                    ],
                  ),
                ),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.imageAsset, required this.isSelected});

  final String imageAsset;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? QeranColors.gold : QeranColors.wine12,
          width: isSelected ? 3 : 1,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          imageAsset,
          fit: BoxFit.cover,
          width: 100,
          height: 100,
        ),
      ),
    );
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: QeranColors.wine,
      ),
      child: const Icon(Icons.check_rounded, size: 14, color: QeranColors.paper),
    );
  }
}
