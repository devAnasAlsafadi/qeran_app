import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/widgets/exit_app_dialog.dart';
import '../../../blocs/questionnaire_cubit.dart';
import '../../../blocs/questionnaire_state.dart';
import '../../../widgets/question_renderer.dart';
import 'category_progress_calculator.dart';
import 'question_header.dart';
import 'questionnaire_app_bar.dart';
import 'questionnaire_navigation_button.dart';

class QuestionnaireFlowBody extends StatelessWidget {
  const QuestionnaireFlowBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuestionnaireCubit, QuestionnaireState>(
      listener: (context, state) {
        if (state is QuestionnaireReadyForOath) {
          // Submit-after-oath flow: hand the prepared payload to the Oath
          // screen, which is responsible for /api/Questions/submit.
          NavigationManager.navigateAndReplace(
            context,
            RouteNames.oathScreen,
            arguments: state.answersPayload,
          );
        } else if (state is QuestionnaireFetched) {
          context.read<QuestionnaireCubit>().startFlow(state.questions);
        } else if (state is QuestionnaireFailure) {
          AppSnackBar.show(
            context,
            message: state.message.t(context),
            type: SnackBarType.error,
          );
        }
      },
      builder: (context, state) {
        final QuestionnaireInProgress? inProgressState =
            state is QuestionnaireInProgress
            ? state
            : (context.read<QuestionnaireCubit>().state
                      is QuestionnaireInProgress
                  ? context.read<QuestionnaireCubit>().state
                        as QuestionnaireInProgress
                  : null);

        if (inProgressState == null) {
          return const Scaffold(
            body: Center(child: QeranLoader()),
          );
        }

        final categorySteps = CategoryProgressCalculator.buildSteps(
          inProgressState.questions,
        );

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              if (inProgressState.isFirst) {
                ExitAppDialog.show(context);
              } else {
                context.read<QuestionnaireCubit>().previousQuestion();
              }
            }
          },
          child: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: QeranSpacing.s24,
                  vertical: QeranSpacing.s16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    QuestionnaireAppBar(
                      isFirst: inProgressState.isFirst,
                      categoryName: inProgressState.currentQuestion.categoryName,
                      steps: categorySteps,
                      currentQuestionIndex: inProgressState.currentIndex,
                      questions: inProgressState.questions,
                      answers: inProgressState.answers,
                      onBack: () {
                        if (inProgressState.isFirst) {
                          ExitAppDialog.show(context);
                        } else {
                          context.read<QuestionnaireCubit>().previousQuestion();
                        }
                      },
                    ),
                    QeranSpacing.vs32,
                    QuestionHeader(
                      question: inProgressState.currentQuestion,
                    ),
                    QeranSpacing.vs24,
                    Expanded(
                      child: SingleChildScrollView(
                        child: QuestionRenderer(
                          key: ValueKey(
                            inProgressState.currentQuestion.questionId,
                          ),
                          question: inProgressState.currentQuestion,
                          currentAnswer: inProgressState
                              .answers[inProgressState
                                  .currentQuestion.questionId],
                          onAnswerChanged: (value) {
                            context
                                .read<QuestionnaireCubit>()
                                .answerQuestion(
                                  inProgressState.currentQuestion.questionId,
                                  value,
                                );
                          },
                        ),
                      ),
                    ),
                    QeranSpacing.vs16,
                    QuestionnaireNavigationButton(
                      isLast: inProgressState.isLast,
                      isLoading: false,
                      enabled: inProgressState.hasCurrentAnswer,
                      onNext: () =>
                          context.read<QuestionnaireCubit>().nextQuestion(),
                      onFinish: () => context
                          .read<QuestionnaireCubit>()
                          .prepareForOath(),
                    ),
                    QeranSpacing.vs16,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
