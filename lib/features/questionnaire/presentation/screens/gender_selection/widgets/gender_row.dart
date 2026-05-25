import 'package:flutter/material.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/utils/app_dimens.dart';
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
            const SizedBox(width: AppDimens.p16),
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
