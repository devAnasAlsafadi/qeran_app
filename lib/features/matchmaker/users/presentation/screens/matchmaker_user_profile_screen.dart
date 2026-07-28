import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/profile/presentation/widgets/states/profile_details_skeleton.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/matchmaker_answer_save_cubit.dart';
import '../blocs/matchmaker_profile_detail_cubit.dart';
import '../blocs/matchmaker_profile_detail_state.dart';
import '../widgets/matchmaker_profile_body.dart';
import '../widgets/matchmaker_profile_edit_host.dart';

/// Matchmaker view of a user's full profile
/// (`GET /matchmaker/users/{id}/profile`). Images are never blurred and the
/// email is visible — both matchmaker privileges. Approve / reject live on the
/// list card (M3b). Text answers are edited INLINE on the profile (PV3; see
/// `MatchmakerProfileEditHost` for the status gate) — the standalone
/// edit-answers screen was removed in PV4.
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
        // Shared by the inline text-answer pencils + their editor sheet.
        BlocProvider(
          create: (_) => sl<MatchmakerAnswerSaveCubit>(param1: userId),
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
      body: SafeArea(
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
                        // Installs the edit scope (pencils on text answers) only
                        // when the profile is editable; user app never mounts
                        // this, so it never shows pencils.
                        child: MatchmakerProfileEditHost(
                          profile: profile,
                          child: MatchmakerProfileBody(profile: profile),
                        ),
                      ),
                    ),
                  MatchmakerProfileDetailError(:final message) =>
                    QeranErrorState(
                      title:
                          LocaleKeys.matchmaker_profile_error_title.t(context),
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
          ],
        ),
      ),
    );
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
