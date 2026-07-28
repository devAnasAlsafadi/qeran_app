import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_sheet.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/matchmaker_user_notes_cubit.dart';
import '../blocs/matchmaker_user_notes_state.dart';
import 'matchmaker_notes_editor.dart';

/// Bottom sheet to view / create / edit / delete the matchmaker's private note
/// about [userId]. Self-contained: creates its own [MatchmakerUserNotesCubit]
/// and loads on open (like the M3b review sheet). Assigned-users only — an
/// UNAUTHORIZED outcome toasts + closes.
Future<void> showMatchmakerNotesSheet(
  BuildContext context, {
  required String userId,
}) {
  return showQeranBottomSheet<void>(
    context: context,
    builder: (_) => BlocProvider<MatchmakerUserNotesCubit>(
      create: (_) => sl<MatchmakerUserNotesCubit>(param1: userId)..load(),
      child: const _NotesSheet(),
    ),
  );
}

class _NotesSheet extends StatelessWidget {
  const _NotesSheet();

  void _onOutcome(BuildContext context, MatchmakerUserNotesState state) {
    switch (state.outcome) {
      case MatchmakerNotesOutcome.saveSuccess:
        _toast(LocaleKeys.matchmaker_notes_saved.t(context),
            SnackBarType.success);
        Navigator.of(context).pop();
      case MatchmakerNotesOutcome.deleteSuccess:
        _toast(LocaleKeys.matchmaker_notes_deleted.t(context),
            SnackBarType.success);
        Navigator.of(context).pop();
      case MatchmakerNotesOutcome.failure:
        _onFailure(context, state.errorKind, state.outcomeMessage);
      case MatchmakerNotesOutcome.none:
        break;
    }
  }

  void _onFailure(
    BuildContext context,
    MatchmakerNotesErrorKind kind,
    String? message,
  ) {
    switch (kind) {
      case MatchmakerNotesErrorKind.unauthorized:
        _toast(LocaleKeys.matchmaker_notes_unauthorized.t(context),
            SnackBarType.error);
        Navigator.of(context).pop();
      case MatchmakerNotesErrorKind.userNotFound:
        _toast(LocaleKeys.matchmaker_notes_user_not_found.t(context),
            SnackBarType.error);
        Navigator.of(context).pop();
      case MatchmakerNotesErrorKind.validation:
        break; // handled inline by the editor
      case MatchmakerNotesErrorKind.generic:
      case MatchmakerNotesErrorKind.none:
        _toast((message ?? LocaleKeys.errors_generic).t(context),
            SnackBarType.error);
    }
  }

  void _toast(String message, SnackBarType type) =>
      AppSnackBar.showOnRoot(message: message, type: type);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MatchmakerUserNotesCubit, MatchmakerUserNotesState>(
      listenWhen: (p, c) => p.eventVersion != c.eventVersion,
      listener: _onOutcome,
      buildWhen: (p, c) => p.load != c.load,
      builder: (context, state) => QeranBottomSheetScaffold(
        title: LocaleKeys.matchmaker_notes_title.t(context),
        // The editor hosts a multiline field — the body MUST scroll or the
        // keyboard overflows it (this sheet was the reported 51px overflow).
        scrollableBody: true,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s20,
            QeranSpacing.s4,
            QeranSpacing.s20,
            QeranSpacing.s16,
          ),
          child: _body(context, state),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, MatchmakerUserNotesState state) {
    switch (state.load) {
      case MatchmakerNotesLoad.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: QeranSpacing.s32),
          child: Center(child: QeranLoader()),
        );
      case MatchmakerNotesLoad.error:
        return QeranErrorState(
          title: LocaleKeys.matchmaker_notes_load_error.t(context),
          message:
              (state.loadErrorMessage ?? LocaleKeys.errors_generic).t(context),
          retryLabel: LocaleKeys.matchmaker_users_retry.t(context),
          onRetry: () => context.read<MatchmakerUserNotesCubit>().load(),
        );
      case MatchmakerNotesLoad.ready:
        return MatchmakerNotesEditor(initialContent: state.note?.content);
    }
  }
}
