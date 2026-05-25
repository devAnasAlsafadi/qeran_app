import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_assets.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/widgets/onboarding_pop_scope.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import '../../blocs/oath/oath_cubit.dart';
import '../../blocs/oath/oath_state.dart';
import 'widgets/oath_checkbox_row.dart';
import 'widgets/oath_footer.dart';
import 'widgets/oath_text_box.dart';
import 'widgets/oath_title_ornament.dart';

class OathScreen extends StatefulWidget {
  /// Answers payload prepared by `QuestionnaireCubit.prepareForOath()` and
  /// passed via `RouteSettings.arguments`. `/api/Questions/submit` runs only
  /// after the oath is signed, so we hold the payload until then.
  final List<Map<String, dynamic>>? answersPayload;

  const OathScreen({super.key, this.answersPayload});

  @override
  State<OathScreen> createState() => _OathScreenState();
}

class _OathScreenState extends State<OathScreen> {
  bool _isChecked = false;

  void _onSwear(BuildContext context) {
    if (!_isChecked) return;
    final payload = widget.answersPayload;
    if (payload == null) {
      // Defensive: nothing to submit (e.g. screen was navigated to without
      // arguments). Send the user back to the start of the onboarding block.
      AppSnackBar.show(
        context,
        message: LocaleKeys.errors_generic.t(context),
        type: SnackBarType.error,
      );
      NavigationManager.pushNamedAndRemoveUntil(
        context,
        RouteNames.genderSelectionScreen,
      );
      return;
    }
    context.read<OathCubit>().submitOath(payload);
  }

  void _onStateChanged(BuildContext context, OathState state) {
    if (state is OathSubmitted) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.questionnaire_oath_accepted.t(context),
        type: SnackBarType.success,
      );
      NavigationManager.navigateAndReplace(
        context,
        RouteNames.photoUploadScreen,
      );
    } else if (state is OathFailure) {
      AppSnackBar.show(
        context,
        message: state.message.t(context),
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OathCubit>(),
      child: Builder(
        builder: (context) => BlocConsumer<OathCubit, OathState>(
          listener: _onStateChanged,
          builder: (context, state) {
            final isSubmitting = state is OathSubmitting;
            return OnboardingPopScope(
              child: Scaffold(
                backgroundColor: AppColors.background,
                body: SafeArea(
                  child: Stack(
                    children: [
                      _OathBody(
                        isChecked: _isChecked,
                        isSubmitting: isSubmitting,
                        onChecked: (v) => setState(() => _isChecked = v),
                        onSwear: () => _onSwear(context),
                      ),
                      if (isSubmitting)
                        Container(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OathBody extends StatelessWidget {
  final bool isChecked;
  final bool isSubmitting;
  final ValueChanged<bool> onChecked;
  final VoidCallback onSwear;

  const _OathBody({
    required this.isChecked,
    required this.isSubmitting,
    required this.onChecked,
    required this.onSwear,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.p24,
            vertical: AppDimens.p16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppDimens.p24),
                Center(
                  child: Image.asset(AppAssets.logo, width: 140),
                ),
                const SizedBox(height: AppDimens.p32),
                Center(
                  child: Text(
                    LocaleKeys.auth_oath_title.t(context),
                    style: AppTextStyles.displayLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: AppDimens.p12),
                const Center(child: OathTitleOrnament()),
                const SizedBox(height: AppDimens.p32),
                const OathTextBox(),
                const SizedBox(height: AppDimens.p24),
                OathCheckboxRow(
                  isChecked: isChecked,
                  onChanged: isSubmitting ? (_) {} : onChecked,
                ),
                const SizedBox(height: AppDimens.p32),
                OathFooter(
                  isChecked: isChecked && !isSubmitting,
                  onSwear: onSwear,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
