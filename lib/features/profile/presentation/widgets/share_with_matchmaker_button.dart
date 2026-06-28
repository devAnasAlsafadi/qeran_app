import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../blocs/share_with_matchmaker/share_with_matchmaker_cubit.dart';
import '../blocs/share_with_matchmaker/share_with_matchmaker_state.dart';

/// Inline pill button rendered on the Full Profile Details screen
/// (other-user variant only). Drops a typed share request via
/// [ShareWithMatchmakerCubit] after a confirm dialog; surfaces
/// outcomes via snackbars. Hidden by entry source upstream — this
/// widget assumes it should render whenever it's mounted.
class ShareWithMatchmakerButton extends StatelessWidget {
  final String userId;
  const ShareWithMatchmakerButton({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ShareWithMatchmakerCubit>(
      create: (_) => sl<ShareWithMatchmakerCubit>()..resolveMatchmaker(),
      child: _Button(userId: userId),
    );
  }
}

class _Button extends StatelessWidget {
  final String userId;
  const _Button({required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ShareWithMatchmakerCubit, ShareWithMatchmakerState>(
      listenWhen: (prev, curr) =>
          prev.eventVersion != curr.eventVersion &&
          curr.event != ShareEvent.none,
      listener: _onEvent,
      builder: (context, state) {
        final cubit = context.read<ShareWithMatchmakerCubit>();
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s20,
            vertical: QeranSpacing.s8,
          ),
          child: QeranButton(
            label:
                LocaleKeys.profile_share_with_matchmaker_cta.t(context),
            onPressed: () => _onTap(context, cubit, state),
            loading: state.isSharing,
            leadingIcon: Icons.chat_bubble_outline_rounded,
          ),
        );
      },
    );
  }

  Future<void> _onTap(
    BuildContext context,
    ShareWithMatchmakerCubit cubit,
    ShareWithMatchmakerState state,
  ) async {
    if (state.isSharing) return;
    if (!state.hasMatchmaker) {
      AppSnackBar.show(
        context,
        message: LocaleKeys.profile_share_no_matchmaker.t(context),
        type: SnackBarType.info,
      );
      return;
    }
    final confirmed = await _confirmDialog(context);
    if (confirmed != true) return;
    await cubit.share(userId);
  }

  Future<bool?> _confirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(LocaleKeys.profile_share_confirm_title.t(dialogCtx)),
        content: Text(LocaleKeys.profile_share_confirm_body.t(dialogCtx)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(
              LocaleKeys.profile_share_confirm_cancel.t(dialogCtx),
              style: const TextStyle(color: QeranColors.inkMuted),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: QeranColors.wine,
            ),
            child: Text(LocaleKeys.profile_share_confirm_send.t(dialogCtx)),
          ),
        ],
      ),
    );
  }

  void _onEvent(BuildContext context, ShareWithMatchmakerState state) {
    final (key, type) = _visualFor(state.event);
    if (key == null) return;
    AppSnackBar.show(context, message: key.t(context), type: type);
  }

  (String?, SnackBarType) _visualFor(ShareEvent event) {
    switch (event) {
      case ShareEvent.none:
        return (null, SnackBarType.info);
      case ShareEvent.success:
        return (LocaleKeys.profile_share_success, SnackBarType.success);
      case ShareEvent.noMatchmaker:
        return (LocaleKeys.profile_share_no_matchmaker, SnackBarType.info);
      case ShareEvent.validation:
        return (LocaleKeys.profile_share_validation, SnackBarType.info);
      case ShareEvent.rateLimited:
        return (LocaleKeys.profile_share_rate_limited, SnackBarType.info);
      case ShareEvent.conversationNotFound:
        return (
          LocaleKeys.profile_share_conversation_not_found,
          SnackBarType.error,
        );
      case ShareEvent.unauthorized:
        return (LocaleKeys.profile_share_unauthorized, SnackBarType.error);
      case ShareEvent.profileNotFound:
        return (LocaleKeys.profile_share_profile_not_found, SnackBarType.info);
      case ShareEvent.failure:
        return (LocaleKeys.profile_share_failure, SnackBarType.error);
    }
  }
}
