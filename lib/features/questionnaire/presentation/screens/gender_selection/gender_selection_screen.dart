import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_assets.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/widgets/app_button.dart';
import '../../blocs/questionnaire_cubit.dart';
import '../../blocs/questionnaire_state.dart';
import '../../controllers/gender_selection_controller.dart';

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
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.p24,
                vertical: AppDimens.p16,
              ),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  // ── Header ──
                  Text(
                    'مرحبا بك',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  AppDimens.verticalSpace8,
                  Text(
                    'اختر هويتك للبدء',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppDimens.verticalSpace8,
                  Text(
                    'نستخدم هذه المعلومة ل تحسين تجربتك',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimens.p32),
                  // ── Gender Cards ──
                  _GenderRow(controller: _controller),
                  const Spacer(flex: 3),
                  // ── CTA ──
                  _ContinueButton(controller: _controller),
                  const SizedBox(height: AppDimens.p24),
                ],
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
        message: state.message,
        type: SnackBarType.error,
      );
    }
  }
}

// ─── Gender Row ─────────────────────────────────────────────────

class _GenderRow extends StatelessWidget {
  final GenderSelectionController controller;

  const _GenderRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Gender?>(
      valueListenable: controller.selectedGenderNotifier,
      builder: (context, selectedGender, _) {
        return Row(
          children: [
            Expanded(
              child: _GenderCard(
                gender: Gender.female,
                isSelected: selectedGender == Gender.female,
                onTap: () => controller.selectGender(Gender.female),
              ),
            ),
            const SizedBox(width: AppDimens.p16),
            Expanded(
              child: _GenderCard(
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

// ─── Gender Card ────────────────────────────────────────────────

class _GenderCard extends StatelessWidget {
  final Gender gender;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.gender,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMale = gender == Gender.male;
    final String imageAsset = isMale ? AppAssets.male : AppAssets.female;
    final String label = isMale ? 'رجل' : 'امرأة';
    final Color cardBg = isMale
        ? const Color(0xFFF5F5F5)
        : const Color(0xFFF8E8EE);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppDimens.p16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: AppDimens.borderRadius16,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Circular image with selection ring
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2ABFE8)
                      : AppColors.border,
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
            ),
            const SizedBox(height: AppDimens.p12),
            Text(
              label,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Continue Button ────────────────────────────────────────────

class _ContinueButton extends StatelessWidget {
  final GenderSelectionController controller;

  const _ContinueButton({required this.controller});

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
              text: isLoading ? 'جاري التحميل...' : 'متابعة',
              onPressed: isEnabled
                  ? () async {
                      await controller.saveGender();
                      if (!context.mounted) return;
                      context
                          .read<QuestionnaireCubit>()
                          .fetchQuestions(gender: selectedGender);
                    }
                  : null,
            );
          },
        );
      },
    );
  }
}
