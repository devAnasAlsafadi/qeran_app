import 'package:easy_localization/easy_localization.dart';
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
import 'package:qeran/features/profile/presentation/blocs/delete_account/delete_account_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/delete_account/delete_account_state.dart';
import 'package:qeran/features/profile/presentation/widgets/delete_consequence_line.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Confirms PERMANENT account deletion: consequence list (incl. an active-
/// subscription forfeit warning with the exact expiry), a case-insensitive
/// typed-confirm gate, then the delete via [DeleteAccountCubit] — on success
/// wipe + redirect to login; on failure a calm notice.
Future<void> showDeleteAccountSheet(
  BuildContext context, {
  required bool subscriptionActive,
  DateTime? expiresAt,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: QeranColors.paper,
    shape: const RoundedRectangleBorder(borderRadius: QeranRadii.domeTop),
    builder: (_) => BlocProvider<DeleteAccountCubit>(
      create: (_) => sl<DeleteAccountCubit>(),
      child: _DeleteAccountSheet(
        subscriptionActive: subscriptionActive,
        expiresAt: expiresAt,
      ),
    ),
  );
}

class _DeleteAccountSheet extends StatefulWidget {
  const _DeleteAccountSheet({
    required this.subscriptionActive,
    required this.expiresAt,
  });

  final bool subscriptionActive;
  final DateTime? expiresAt;

  @override
  State<_DeleteAccountSheet> createState() => _DeleteAccountSheetState();
}

class _DeleteAccountSheetState extends State<_DeleteAccountSheet> {
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

  /// The subscription-forfeit line with the formatted expiry — null when there
  /// is no active subscription (never fabricated).
  String? _subscriptionWarning(BuildContext context) {
    if (!widget.subscriptionActive || widget.expiresAt == null) return null;
    final date =
        DateFormat.yMMMMd(context.locale.toString()).format(widget.expiresAt!);
    return LocaleKeys.settings_delete_account_consequence_subscription
        .t(context)
        .replaceFirst('{date}', date);
  }

  void _onOutcome(BuildContext context, DeleteAccountState state) {
    if (!context.mounted) return;
    switch (state.outcome) {
      case DeleteAccountOutcome.success:
        // Clear sub cache, stack→login, then toast on root (survives the pop).
        context.read<CurrentSubscriptionCubit>().clear();
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
    return BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
      listenWhen: (p, c) =>
          p.eventVersion != c.eventVersion &&
          c.outcome != DeleteAccountOutcome.none,
      listener: _onOutcome,
      builder: (context, state) {
        final subWarning = _subscriptionWarning(context);
        // PopScope: block swipe/back dismiss while the delete is in flight.
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
                  if (subWarning != null) ...[
                    QeranSpacing.vs12,
                    DeleteConsequenceLine(text: subWarning),
                  ],
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
                        ? () => context.read<DeleteAccountCubit>().delete()
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
