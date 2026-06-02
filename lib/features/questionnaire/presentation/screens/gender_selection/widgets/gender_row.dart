import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/enum/gender.dart';
import '../../../controllers/gender_selection_controller.dart';
import 'gender_card.dart';

class GenderRow extends StatelessWidget {
  final GenderSelectionController controller;

  const GenderRow({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Gender?>(
      valueListenable: controller.selectedGenderNotifier,
      builder: (context, selectedGender, _) {
        return Row(
          children: [
            Expanded(
              child: GenderCard(
                gender: Gender.female,
                isSelected: selectedGender == Gender.female,
                onTap: () => controller.selectGender(Gender.female),
              ),
            ),
            QeranSpacing.hs16,
            Expanded(
              child: GenderCard(
                gender: Gender.male,
                isSelected: selectedGender == Gender.male,
                onTap: () => controller.selectGender(Gender.male),
              ),
            ),
          ],
        );
      },
    );
  }
}
