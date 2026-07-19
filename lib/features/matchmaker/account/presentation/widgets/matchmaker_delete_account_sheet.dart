import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_sheet_handle.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/routes/navigation_manager.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/profile/presentation/blocs/delete_account/delete_account_state.dart';
import 'package:qeran/features/profile/presentation/widgets/delete_consequence_line.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/matchmaker_delete_account_cubit.dart';

/// Confirms PERMANENT Moderator account deletion — mirrors the user delete
/// sheet (typed-confirm gate → delete → wipe → login), minus the subscription
/// warning (a matchmaker has no subscription). Reuses the shared
/// `settings_delete_account_*` copy + [DeleteConsequenceLine].
Future<void> showMatchmakerDeleteAccountSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: QeranColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: QeranRadii.domeTop),
    builder: (_) => BlocProvider<MatchmakerDeleteAccountCubit>(
      create: (_) => sl<MatchmakerDeleteAccountCubit>(),
      child: const _MatchmakerDeleteAccountSheet(),
    ),
  );
}

class _MatchmakerDeleteAccountSheet extends StatefulWidget {
  const _MatchmakerDeleteAccountSheet();

  @override
  State<_MatchmakerDeleteAccountSheet> createState() =>
      _MatchmakerDeleteAccountSheetState();
}

class _MatchmakerDeleteAccountSheetState
    extends State<_MatchmakerDeleteAccountSheet> {
  final TextEditingController _confirm = TextEditingController();

  @override
  void dispose() {
    _confirm.dispose();
    super.dispose();
  }

  /// Case-insensitive match against the localized confirm word («حذف» / DELETE).
  bool _matches(BuildContext context) {
    final word = LocaleKeys.settings_delete_account_confirm_word.t(context);
    return _confirm.text.trim().toLowerCase() == word.toLowerCase();
  }

  void _onOutcome(BuildContext context, DeleteAccountState state) {
    if (!context.mounted) return;
    switch (state.outcome) {
      case DeleteAccountOutcome.success:
        NavigationManager.pushNamedAndRemoveUntil(
            context, RouteNames.loginScreen);
        AppSnackBar.showOnRoot(
          message: LocaleKeys.settings_delete_account_success.t(context),
          type: SnackBarType.success,
        );
      case DeleteAccountOutcome.failure:
        AppSnackBar.show(
          context,
          message: LocaleKeys.settings_delete_account_failed.t(context),
          type: SnackBarType.notice,
        );
      case DeleteAccountOutcome.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MatchmakerDeleteAccountCubit, DeleteAccountState>(
      listenWhen: (p, c) =>
          p.eventVersion != c.eventVersion &&
          c.outcome != DeleteAccountOutcome.none,
      listener: _onOutcome,
      builder: (context, state) {
        return PopScope(
          canPop: !state.deleting,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              QeranSpacing.s20,
              QeranSpacing.s12,
              QeranSpacing.s20,
              QeranSpacing.s20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: QeranSheetHandle()),
                  QeranSpacing.vs16,
                  Row(
                    children: [
                      const Icon(Icons.delete_forever_outlined,
                          color: QeranColors.danger, size: 24),
                      QeranSpacing.hs8,
                      Expanded(
                        child: Text(
                          LocaleKeys.settings_delete_account_sheet_title
                              .t(context),
                          style: QeranTypography.title
                              .copyWith(color: QeranColors.danger),
                        ),
                      ),
                    ],
                  ),
                  QeranSpacing.vs16,
                  DeleteConsequenceLine(
                    text: LocaleKeys
                        .settings_delete_account_consequence_permanent
                        .t(context),
                  ),
                  QeranSpacing.vs12,
                  DeleteConsequenceLine(
                    text: LocaleKeys.settings_delete_account_consequence_data
                        .t(context),
                  ),
                  QeranSpacing.vs20,
                  QeranTextField(
                    controller: _confirm,
                    hint: LocaleKeys.settings_delete_account_confirm_hint
                        .t(context),
                    onChanged: (_) => setState(() {}),
                  ),
                  QeranSpacing.vs20,
                  QeranButton(
                    label: LocaleKeys.settings_delete_account_confirm_button
                        .t(context),
                    variant: QeranButtonVariant.destructive,
                    loading: state.deleting,
                    onPressed: _matches(context)
                        ? () => context
                            .read<MatchmakerDeleteAccountCubit>()
                            .delete()
                        : null,
                  ),
                  QeranSpacing.vs8,
                  QeranButton(
                    label: LocaleKeys.common_cancel.t(context),
                    variant: QeranButtonVariant.ghost,
                    onPressed: state.deleting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
