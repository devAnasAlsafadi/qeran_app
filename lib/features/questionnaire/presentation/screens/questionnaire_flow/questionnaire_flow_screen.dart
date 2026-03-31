import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/widgets/app_button.dart';
import '../../../domain/entities/question_entity.dart';
import '../../blocs/questionnaire_cubit.dart';
import '../../blocs/questionnaire_state.dart';
import '../../widgets/question_progress_bar.dart';
import '../../widgets/question_renderer.dart';

class QuestionnaireFlowScreen extends StatelessWidget {
  final List<QuestionEntity> questions;

  const QuestionnaireFlowScreen({super.key, required this.questions});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<QuestionnaireCubit>()..startFlow(questions),
      child: const _QuestionnaireFlowBody(),
    );
  }
}

class _QuestionnaireFlowBody extends StatelessWidget {
  const _QuestionnaireFlowBody();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<QuestionnaireCubit, QuestionnaireState>(
      listener: (context, state) {
        if (state is QuestionnaireCompleted) {
          NavigationManager.pushNamedAndRemoveUntil(
            context,
            RouteNames.homeScreen,
          );
        }
      },
      builder: (context, state) {
        if (state is! QuestionnaireInProgress) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return PopScope(
          canPop: state.isFirst,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) {
              context.read<QuestionnaireCubit>().previousQuestion();
            }
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.p24,
                  vertical: AppDimens.p16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Back Button ──
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left, size: 28),
                        onPressed: () {
                          if (state.isFirst) {
                            NavigationManager.pop(context);
                          } else {
                            context
                                .read<QuestionnaireCubit>()
                                .previousQuestion();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: AppDimens.p8),
                    // ── Progress Bar ──
                    QuestionProgressBar(progress: state.progress),
                    const SizedBox(height: AppDimens.p32),
                    // ── Question Text ──
                    Text(
                      state.currentQuestion.text,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimens.p24),
                    // ── Answer Area ──
                    Expanded(
                      child: SingleChildScrollView(
                        child: QuestionRenderer(
                          key: ValueKey(state.currentQuestion.questionId),
                          question: state.currentQuestion,
                          currentAnswer:
                              state.answers[state.currentQuestion.questionId],
                          onAnswerChanged: (value) {
                            context.read<QuestionnaireCubit>().answerQuestion(
                                  state.currentQuestion.questionId,
                                  value,
                                );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDimens.p16),
                    // ── Next / Finish Button ──
                    CustomButton(
                      text: state.isLast ? 'إنهاء' : 'التالي',
                      onPressed: state.hasCurrentAnswer
                          ? () =>
                              context.read<QuestionnaireCubit>().nextQuestion()
                          : null,
                    ),
                    const SizedBox(height: AppDimens.p16),
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
