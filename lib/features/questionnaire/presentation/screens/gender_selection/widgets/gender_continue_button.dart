import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/widgets/app_button.dart';
import '../../../blocs/questionnaire_cubit.dart';
import '../../../blocs/questionnaire_state.dart';
import '../../../controllers/gender_selection_controller.dart';

class GenderContinueButton extends StatelessWidget {
  final GenderSelectionController controller;

  const GenderContinueButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QuestionnaireCubit, QuestionnaireState>(
      builder: (context, state) {
        return ValueListenableBuilder<Gender?>(
          valueListenable: controller.selectedGenderNotifier,
          builder: (context, selectedGender, _) {
            final isLoading = state is QuestionnaireLoading;
            final isEnabled = selectedGender != null && !isLoading;
            return CustomButton(
              text: LocaleKeys.questionnaire_continue_button.t(context),
              isLoading: isLoading,
              onPressed: isEnabled
                  ? () async {
                      await controller.saveGender();
                      if (!context.mounted) return;
                      context.read<QuestionnaireCubit>().fetchQuestions(
                        gender: selectedGender,
                      );
                    }
                  : null,
            );
          },
        );
      },
    );
  }
}
