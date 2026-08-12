import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/profile/presentation/widgets/states/profile_details_skeleton.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/matchmaker_answer_save_cubit.dart';
import '../blocs/matchmaker_profile_detail_cubit.dart';
import '../blocs/matchmaker_profile_detail_state.dart';
import '../blocs/matchmaker_user_actions_cubit.dart';
import '../blocs/matchmaker_user_actions_state.dart';
import '../matchmaker_user_profile_args.dart';
import '../widgets/matchmaker_profile_body.dart';
import '../widgets/matchmaker_profile_edit_host.dart';
import '../../../colleagues/presentation/widgets/matchmaker_colleague_open_chat_host.dart';

/// Matchmaker view of a user's full profile
/// (`GET /matchmaker/users/{id}/profile`). Images are never blurred and the
/// email is visible — both matchmaker privileges. Approve / reject live on the
/// list card (M3b). Text answers are edited INLINE on the profile (PV3; see
/// `MatchmakerProfileEditHost` for the status gate) — the standalone
/// edit-answers screen was removed in PV4.
class MatchmakerUserProfileScreen extends StatelessWidget {
  const MatchmakerUserProfileScreen({super.key, required this.args});

  final MatchmakerUserProfileArgs args;

  @override
  Widget build(BuildContext context) {
    final content = MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<MatchmakerProfileDetailCubit>(param1: args.userId)..load(),
        ),
        // Shared by the inline text-answer pencils + their editor sheet.
        BlocProvider(
          create: (_) => sl<MatchmakerAnswerSaveCubit>(param1: args.userId),
        ),
        BlocProvider(
          create: (_) => sl<MatchmakerUserActionsCubit>(param1: args.userId),
        ),
      ],
      child: _ProfileDetailView(
        responsibleMatchmaker: args.responsibleMatchmaker,
      ),
    );
    if (args.responsibleMatchmaker == null) return content;
    return MatchmakerColleagueOpenChatHost(child: content);
  }
}

class _ProfileDetailView extends StatelessWidget {
  const _ProfileDetailView({required this.responsibleMatchmaker});

  final ResponsibleMatchmakerContact? responsibleMatchmaker;

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchmakerUserActionsCubit, MatchmakerUserActionsState>(
      listenWhen: (previous, current) =>
          previous.eventVersion != current.eventVersion,
      listener: _onImageApproval,
      child: Scaffold(
        backgroundColor: QeranColors.creamCanvas,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child:
                    BlocBuilder<
                      MatchmakerProfileDetailCubit,
                      MatchmakerProfileDetailState
                    >(
                      builder: (context, state) => switch (state) {
                        MatchmakerProfileDetailLoaded(:final profile) =>
                          RefreshIndicator(
                            color: QeranColors.wine,
                            backgroundColor: QeranColors.paper,
                            onRefresh: () => context
                                .read<MatchmakerProfileDetailCubit>()
                                .refresh(),
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics(),
                              ),
                              child: MatchmakerProfileEditHost(
                                profile: profile,
                                child: MatchmakerProfileBody(
                                  profile: profile,
                                  responsibleMatchmaker: responsibleMatchmaker,
                                ),
                              ),
                            ),
                          ),
                        MatchmakerProfileDetailError(:final message) =>
                          QeranErrorState(
                            title: LocaleKeys.matchmaker_profile_error_title.t(
                              context,
                            ),
                            message: message.t(context),
                            retryLabel: LocaleKeys.matchmaker_profile_retry.t(
                              context,
                            ),
                            onRetry: () => context
                                .read<MatchmakerProfileDetailCubit>()
                                .retry(),
                          ),
                        _ => const ProfileDetailsSkeleton(),
                      },
                    ),
              ),
              const PositionedDirectional(
                top: 8,
                start: 8,
                child: _BackButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onImageApproval(
    BuildContext context,
    MatchmakerUserActionsState state,
  ) {
    if (state.outcome == MatchmakerActionOutcome.approveImageSuccess) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.matchmaker_profile_image_approved.t(context),
        type: SnackBarType.success,
      );
      context.read<MatchmakerProfileDetailCubit>().refresh();
      return;
    }
    if (state.outcome != MatchmakerActionOutcome.failure ||
        state.inFlight != null) {
      return;
    }
    final message = state.errorKind == MatchmakerActionErrorKind.unauthorized
        ? LocaleKeys.matchmaker_user_not_assigned
        : (state.errorMessage ?? LocaleKeys.errors_generic);
    AppSnackBar.show(
      context,
      message: message.t(context),
      type: SnackBarType.error,
    );
    if (state.errorKind == MatchmakerActionErrorKind.unauthorized) {
      context.read<MatchmakerProfileDetailCubit>().refresh();
    }
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QeranColors.paper,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => NavigationManager.pop(context),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.chevron_left_rounded,
            color: QeranColors.wine,
            size: 22,
          ),
        ),
      ),
    );
  }
}
