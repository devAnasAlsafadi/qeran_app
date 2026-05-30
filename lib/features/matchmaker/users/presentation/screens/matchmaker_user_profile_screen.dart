import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/features/profile/presentation/widgets/states/profile_details_skeleton.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/matchmaker_profile_detail_cubit.dart';
import '../blocs/matchmaker_profile_detail_state.dart';
import '../blocs/matchmaker_user_actions_cubit.dart';
import '../blocs/matchmaker_user_actions_state.dart';
import '../widgets/matchmaker_edit_answers_button.dart';
import '../widgets/matchmaker_profile_action_bar.dart';
import '../widgets/matchmaker_profile_body.dart';

/// Read-only matchmaker view of a user's full profile
/// (`GET /matchmaker/users/{id}/profile`). Images are never blurred and the
/// email is visible — both matchmaker privileges. When the profile is
/// PendingReview a bottom action bar offers approve / reject / request-photo.
class MatchmakerUserProfileScreen extends StatelessWidget {
  const MatchmakerUserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              sl<MatchmakerProfileDetailCubit>(param1: userId)..load(),
        ),
        BlocProvider(
          create: (_) => sl<MatchmakerUserActionsCubit>(param1: userId),
        ),
      ],
      child: const _ProfileDetailView(),
    );
  }
}

class _ProfileDetailView extends StatelessWidget {
  const _ProfileDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      bottomNavigationBar: const MatchmakerProfileActionBar(),
      body:
          BlocListener<MatchmakerUserActionsCubit, MatchmakerUserActionsState>(
        listenWhen: (prev, curr) => prev.eventVersion != curr.eventVersion,
        listener: _onActionOutcome,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: BlocBuilder<MatchmakerProfileDetailCubit,
                    MatchmakerProfileDetailState>(
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
                          child: MatchmakerProfileBody(profile: profile),
                        ),
                      ),
                    MatchmakerProfileDetailError(:final message) =>
                      QeranErrorState(
                        title: LocaleKeys.matchmaker_profile_error_title
                            .t(context),
                        message: message.t(context),
                        retryLabel:
                            LocaleKeys.matchmaker_profile_retry.t(context),
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
              const PositionedDirectional(
                top: 8,
                end: 8,
                child: MatchmakerEditAnswersButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onActionOutcome(
    BuildContext context,
    MatchmakerUserActionsState state,
  ) {
    switch (state.outcome) {
      case MatchmakerActionOutcome.approveSuccess:
        _successAndPop(
          context,
          LocaleKeys.matchmaker_profile_approve_success.t(context),
        );
      case MatchmakerActionOutcome.rejectSuccess:
        _successAndPop(
          context,
          LocaleKeys.matchmaker_profile_reject_success.t(context),
        );
      case MatchmakerActionOutcome.requestImageSuccess:
        AppSnackBar.show(
          context,
          message:
              LocaleKeys.matchmaker_profile_request_image_success.t(context),
          type: SnackBarType.success,
        );
      case MatchmakerActionOutcome.failure:
        AppSnackBar.show(
          context,
          message:
              (state.errorMessage ?? LocaleKeys.errors_generic).t(context),
          type: SnackBarType.error,
        );
      case MatchmakerActionOutcome.none:
        break;
    }
  }

  /// Approve / reject leave the user's pending row stale, so pop with `true`
  /// to tell the list to refresh. The snackbar fires on the root overlay so
  /// it survives the pop.
  void _successAndPop(BuildContext context, String message) {
    AppSnackBar.showOnRoot(message: message, type: SnackBarType.success);
    NavigationManager.pop(context, true);
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
            Icons.arrow_back_rounded,
            color: QeranColors.wine,
            size: 22,
          ),
        ),
      ),
    );
  }
}
