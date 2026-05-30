import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/routes/navigation_manager.dart';
import '../../../../../core/routes/route_name.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/matchmaker_profile_detail_cubit.dart';
import '../blocs/matchmaker_profile_detail_state.dart';

/// Floating entry point (top-trailing of the profile detail) that opens the
/// editable-answers screen. Visible ONLY when the loaded profile is
/// PendingReview or Rejected — the backend rejects edits on approved users,
/// so the UI never offers it otherwise.
class MatchmakerEditAnswersButton extends StatelessWidget {
  const MatchmakerEditAnswersButton({super.key});

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<MatchmakerProfileDetailCubit>().state;
    if (detail is! MatchmakerProfileDetailLoaded) {
      return const SizedBox.shrink();
    }
    final status = detail.profile.profileStatus;
    final eligible = status == ProfileStatus.pendingReview ||
        status == ProfileStatus.rejected;
    if (!eligible) return const SizedBox.shrink();

    final userId = context.read<MatchmakerProfileDetailCubit>().userId;
    return Tooltip(
      message: LocaleKeys.matchmaker_answers_open.t(context),
      child: Material(
        color: QeranColors.paper,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => NavigationManager.navigateTo(
            context,
            RouteNames.matchmakerEditableAnswers,
            arguments: userId,
          ),
          child: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              Icons.edit_note_rounded,
              color: QeranColors.wine,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
