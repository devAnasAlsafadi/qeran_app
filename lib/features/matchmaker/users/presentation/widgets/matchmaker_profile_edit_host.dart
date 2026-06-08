import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/text_answer_edit_scope.dart';

import '../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../domain/entities/matchmaker_user_profile.dart';
import '../blocs/matchmaker_answer_save_cubit.dart';
import '../blocs/matchmaker_answer_save_state.dart';
import '../blocs/matchmaker_profile_detail_cubit.dart';
import 'matchmaker_text_answer_sheet.dart';

/// Installs the [TextAnswerEditScope] around the matchmaker profile body — but
/// ONLY when the profile is editable (`pendingReview` / `rejected`; the backend
/// rejects edits otherwise). When not editable it returns [child] unwrapped, so
/// no scope is present and the P2b pencils never appear. The user-app profile
/// never mounts this host → it never installs the scope → no pencils there.
///
/// The scope's `onEdit` opens the inline text-answer sheet; the save cubit's
/// `inFlightQuestionId` drives the tapped item's loader. On a successful save
/// it shows a snackbar and refreshes the profile so the new answer renders.
class MatchmakerProfileEditHost extends StatelessWidget {
  const MatchmakerProfileEditHost({
    super.key,
    required this.profile,
    required this.child,
  });

  final MatchmakerUserProfile profile;
  final Widget child;

  bool get _editable =>
      profile.profileStatus == ProfileStatus.pendingReview ||
      profile.profileStatus == ProfileStatus.rejected;

  @override
  Widget build(BuildContext context) {
    if (!_editable) return child; // no scope → no pencils

    return BlocListener<MatchmakerAnswerSaveCubit, MatchmakerAnswerSaveState>(
      listenWhen: (p, c) =>
          p.eventVersion != c.eventVersion &&
          c.outcome != AnswerSaveOutcome.none,
      listener: _onOutcome,
      child: BlocBuilder<MatchmakerAnswerSaveCubit, MatchmakerAnswerSaveState>(
        buildWhen: (p, c) => p.inFlightQuestionId != c.inFlightQuestionId,
        builder: (context, save) => TextAnswerEditScope(
          inFlightQuestionId: save.inFlightQuestionId,
          onEdit: (item) => showMatchmakerTextAnswerSheet(
            context,
            cubit: context.read<MatchmakerAnswerSaveCubit>(),
            item: item,
          ),
          child: child,
        ),
      ),
    );
  }

  void _onOutcome(BuildContext context, MatchmakerAnswerSaveState state) {
    if (state.outcome == AnswerSaveOutcome.success) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.matchmaker_answers_save_success.t(context),
        type: SnackBarType.success,
      );
      context.read<MatchmakerProfileDetailCubit>().refresh();
    } else if (state.outcome == AnswerSaveOutcome.failure) {
      AppSnackBar.show(
        context,
        message: (state.errorMessage ?? LocaleKeys.errors_generic).t(context),
        type: SnackBarType.error,
      );
    }
  }
}
