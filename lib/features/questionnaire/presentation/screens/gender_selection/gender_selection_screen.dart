import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/widgets/onboarding_pop_scope.dart';
import '../../blocs/questionnaire_cubit.dart';
import '../../blocs/questionnaire_state.dart';
import '../../controllers/gender_selection_controller.dart';
import 'widgets/gender_continue_button.dart';
import 'widgets/gender_row.dart';

class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  late final GenderSelectionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GenderSelectionController(
      sharedPrefs: sl<SharedPrefService>(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QuestionnaireCubit>(),
      child: BlocListener<QuestionnaireCubit, QuestionnaireState>(
        listener: _onStateChanged,
        child: OnboardingPopScope(
          child: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: QeranSpacing.s24,
                  vertical: QeranSpacing.s16,
                ),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    Text(
                      LocaleKeys.questionnaire_welcome.t(context),
                      textAlign: TextAlign.center,
                      style: QeranTypography.displaySm,
                    ),
                    QeranSpacing.vs8,
                    Text(
                      LocaleKeys.questionnaire_choose_identity.t(context),
                      textAlign: TextAlign.center,
                      style: QeranTypography.headline,
                    ),
                    QeranSpacing.vs8,
                    Text(
                      LocaleKeys.questionnaire_identity_info.t(context),
                      textAlign: TextAlign.center,
                      style: QeranTypography.bodySm.copyWith(
                        color: QeranColors.inkMuted,
                      ),
                    ),
                    QeranSpacing.vs32,
                    GenderRow(controller: _controller),
                    const Spacer(flex: 3),
                    GenderContinueButton(controller: _controller),
                    QeranSpacing.vs24,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onStateChanged(BuildContext context, QuestionnaireState state) {
    if (state is QuestionnaireFetched) {
      AppLogger.info(
        'Questions fetched: ${state.questions.length}',
        tag: 'QUESTIONNAIRE',
      );
      NavigationManager.navigateAndReplace(
        context,
        RouteNames.questionsScreen,
        arguments: state.questions,
      );
    } else if (state is QuestionnaireFailure) {
      AppSnackBar.show(
        context,
        message: state.message.t(context),
        type: SnackBarType.error,
      );
    }
  }
}
