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
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/widgets/onboarding_pop_scope.dart';
import '../../blocs/questionnaire_cubit.dart';
import '../../blocs/questionnaire_state.dart';
import '../../controllers/gender_selection_controller.dart';
import 'widgets/gender_continue_button.dart';
import 'widgets/gender_hero_header.dart';
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
            backgroundColor: QeranColors.wine,
            body: Column(
              children: [
                // Wine hero band (onboarding family: wineLight→wine gradient +
                // ring motif) carrying the heading + language pill.
                const GenderHeroHeader(),
                // Cream dome surfacing out of the hero, holding the two cards
                // and the continue action.
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: QeranColors.creamCanvas,
                      borderRadius: QeranRadii.domeTop,
                      boxShadow: QeranShadows.eLiftUp,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          QeranSpacing.s24,
                          QeranSpacing.s32,
                          QeranSpacing.s24,
                          QeranSpacing.s24,
                        ),
                        child: Column(
                          children: [
                            // Center the cards in the space above the pinned
                            // action (equal flex above/below) so they breathe
                            // rather than sitting high with a dead zone below.
                            const Spacer(),
                            GenderRow(controller: _controller),
                            const Spacer(),
                            GenderContinueButton(controller: _controller),
                            QeranSpacing.vs16,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  size: 16,
                                  color: QeranColors.inkMuted,
                                ),
                                QeranSpacing.hs4,
                                Flexible(
                                  child: Text(
                                    LocaleKeys.questionnaire_gender_privacy
                                        .t(context),
                                    style: QeranTypography.bodySm.copyWith(
                                      color: QeranColors.inkMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
