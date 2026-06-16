import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/design_system/widgets/qeran_sheet_handle.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../blocs/case_note/case_note_cubit.dart';
import '../blocs/case_note/case_note_state.dart';
import 'case_note_editor.dart';

/// Bottom sheet to view / create / edit / delete the matchmaker's private note
/// about case [caseId]. Self-contained: creates its own [CaseNoteCubit] and
/// loads on open (like the M3d user-notes sheet). Strictly per-matchmaker — a
/// NOT_INVOLVED_IN_CASE / UNAUTHORIZED / CASE_NOT_FOUND outcome toasts + closes.
///
/// Resolves to `true` when a note now EXISTS (saved), `false` when it no longer
/// exists (deleted), and `null` when nothing changed (plain cancel / terminal
/// failure) — the caller uses this to update the card's note indicator in place.
Future<bool?> showCaseNoteSheet(
  BuildContext context, {
  required int caseId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: QeranColors.overlayTintDark,
    useSafeArea: true,
    builder: (_) => BlocProvider<CaseNoteCubit>(
      create: (_) => sl<CaseNoteCubit>(param1: caseId)..load(),
      child: const _CaseNoteSheet(),
    ),
  );
}

class _CaseNoteSheet extends StatelessWidget {
  const _CaseNoteSheet();

  void _onOutcome(BuildContext context, CaseNoteState state) {
    switch (state.outcome) {
      case CaseNoteOutcome.saveSuccess:
        _toast(LocaleKeys.matchmaker_notes_saved.t(context),
            SnackBarType.success);
        Navigator.of(context).pop(true); // note now exists
      case CaseNoteOutcome.deleteSuccess:
        _toast(LocaleKeys.matchmaker_notes_deleted.t(context),
            SnackBarType.success);
        Navigator.of(context).pop(false); // note removed
      case CaseNoteOutcome.failure:
        _onFailure(context, state.errorKind, state.outcomeMessage);
      case CaseNoteOutcome.none:
        break;
    }
  }

  void _onFailure(
    BuildContext context,
    CaseNoteErrorKind kind,
    String? message,
  ) {
    switch (kind) {
      case CaseNoteErrorKind.unauthorized:
        _toast(LocaleKeys.matchmaker_notes_unauthorized.t(context),
            SnackBarType.error);
        Navigator.of(context).pop();
      case CaseNoteErrorKind.caseNotFound:
        _toast(LocaleKeys.matchmaker_case_note_not_found.t(context),
            SnackBarType.error);
        Navigator.of(context).pop();
      case CaseNoteErrorKind.notInvolved:
        _toast(LocaleKeys.matchmaker_case_note_not_involved.t(context),
            SnackBarType.error);
        Navigator.of(context).pop();
      case CaseNoteErrorKind.validation:
        break; // handled inline by the editor
      case CaseNoteErrorKind.generic:
      case CaseNoteErrorKind.none:
        _toast((message ?? LocaleKeys.errors_generic).t(context),
            SnackBarType.error);
    }
  }

  void _toast(String message, SnackBarType type) =>
      AppSnackBar.showOnRoot(message: message, type: type);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: QeranColors.paper,
          borderRadius: QeranRadii.domeTop,
          boxShadow: QeranShadows.e3,
        ),
        padding: const EdgeInsets.fromLTRB(
          QeranSpacing.s24,
          QeranSpacing.s12,
          QeranSpacing.s24,
          QeranSpacing.s24,
        ),
        child: BlocConsumer<CaseNoteCubit, CaseNoteState>(
          listenWhen: (p, c) => p.eventVersion != c.eventVersion,
          listener: _onOutcome,
          buildWhen: (p, c) => p.load != c.load,
          builder: (context, state) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const QeranSheetHandle(),
              QeranSpacing.vs20,
              _body(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, CaseNoteState state) {
    switch (state.load) {
      case CaseNoteLoad.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: QeranSpacing.s32),
          child: Center(child: QeranLoader()),
        );
      case CaseNoteLoad.error:
        return QeranErrorState(
          title: LocaleKeys.matchmaker_notes_load_error.t(context),
          message:
              (state.loadErrorMessage ?? LocaleKeys.errors_generic).t(context),
          retryLabel: LocaleKeys.matchmaker_users_retry.t(context),
          onRetry: () => context.read<CaseNoteCubit>().load(),
        );
      case CaseNoteLoad.ready:
        return CaseNoteEditor(
          initialContent: state.note?.content,
          updatedAt: state.note?.updatedAt,
        );
    }
  }
}
