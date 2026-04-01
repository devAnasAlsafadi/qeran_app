import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/widgets/app_button.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/enum/gender.dart';
import '../../../domain/entities/question_entity.dart';
import '../../blocs/questionnaire_cubit.dart';
import '../../blocs/questionnaire_state.dart';
import '../../widgets/question_progress_bar.dart';
import '../../widgets/question_renderer.dart';

class QuestionnaireFlowScreen extends StatelessWidget {
  final List<QuestionEntity>? questions;

  const QuestionnaireFlowScreen({super.key, this.questions});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<QuestionnaireCubit>();
        if (questions != null) {
          cubit.startFlow(questions!);
        } else {
          // Fetch questions if navigating directly from Splash
          sl<SharedPrefService>().get<String>(StorageKeys.gender).then((g) {
            final gender = g == 'female' ? Gender.female : Gender.male;
            cubit.fetchQuestions(gender: gender);
          });
        }
        return cubit;
      },
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
          NavigationManager.navigateAndReplace(
            context,
            RouteNames.oathScreen,
          );
        } else if (state is QuestionnaireSubmissionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is QuestionnaireFetched) {
          context.read<QuestionnaireCubit>().startFlow(state.questions);
        } else if (state is QuestionnaireFailure) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is QuestionnaireSubmitting;

        final QuestionnaireInProgress? inProgressState = 
            state is QuestionnaireInProgress 
            ? state 
            : (context.read<QuestionnaireCubit>().state is QuestionnaireInProgress 
                ? context.read<QuestionnaireCubit>().state as QuestionnaireInProgress 
                : null);

        if (inProgressState == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Stack(
          children: [
            PopScope(
              canPop: inProgressState.isFirst,
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
                              if (inProgressState.isFirst) {
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
                        QuestionProgressBar(progress: inProgressState.progress),
                        const SizedBox(height: AppDimens.p32),
                        // ── Question Text ──
                        Text(
                          inProgressState.currentQuestion.text,
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
                              key: ValueKey(inProgressState.currentQuestion.questionId),
                              question: inProgressState.currentQuestion,
                              currentAnswer:
                                  inProgressState.answers[inProgressState.currentQuestion.questionId],
                              onAnswerChanged: (value) {
                                context.read<QuestionnaireCubit>().answerQuestion(
                                      inProgressState.currentQuestion.questionId,
                                      value,
                                    );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimens.p16),
                        // ── Next / Finish Button ──
                        CustomButton(
                          text: inProgressState.isLast ? 'إنهاء' : 'التالي',
                          onPressed: inProgressState.hasCurrentAnswer && !isSubmitting
                              ? () {
                                  if (inProgressState.isLast) {
                                    context.read<QuestionnaireCubit>().submitAnswers();
                                  } else {
                                    context.read<QuestionnaireCubit>().nextQuestion();
                                  }
                                }
                              : null,
                        ),
                        const SizedBox(height: AppDimens.p16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            if (isSubmitting)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
    );
  }
}
