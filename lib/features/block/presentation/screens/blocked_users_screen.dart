import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_empty_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_error_state.dart';
import 'package:qeran/core/design_system/widgets/qeran_loader.dart';
import 'package:qeran/core/design_system/widgets/qeran_monogram.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/enum/snakebar_tybe.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/settings/presentation/widgets/settings_screen_header.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/blocked_user.dart';
import '../blocs/blocked_list_cubit.dart';
import '../blocs/blocked_list_state.dart';

/// Settings → Blocked users. Lists everyone the account has blocked, with a
/// per-row unblock. Backed by `GET /api/block` + `DELETE /api/block/{id}`.
class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BlockedListCubit>(
      create: (_) => sl<BlockedListCubit>()..load(),
      child: const _BlockedUsersView(),
    );
  }
}

class _BlockedUsersView extends StatelessWidget {
  const _BlockedUsersView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QeranColors.creamCanvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsScreenHeader(
              title: LocaleKeys.block_list_title.t(context),
            ),
            Expanded(
              child: BlocConsumer<BlockedListCubit, BlockedListState>(
                listenWhen: (p, c) =>
                    p.actionVersion != c.actionVersion &&
                    c.actionMessageKey != null,
                listener: (context, state) => AppSnackBar.show(
                  context,
                  message: state.actionMessageKey!.t(context),
                  type: state.actionMessageKey == LocaleKeys.block_unblocked
                      ? SnackBarType.success
                      : SnackBarType.error,
                ),
                builder: (context, state) => switch (state.status) {
                  BlockedListStatus.loading =>
                    const Center(child: QeranLoader()),
                  BlockedListStatus.error => QeranErrorState(
                      title: LocaleKeys.block_list_error.t(context),
                      message: (state.errorKey ?? LocaleKeys.errors_generic)
                          .t(context),
                      retryLabel: LocaleKeys.block_retry.t(context),
                      onRetry: () => context.read<BlockedListCubit>().load(),
                    ),
                  BlockedListStatus.loaded => state.users.isEmpty
                      ? QeranEmptyState(
                          title: LocaleKeys.block_list_empty.t(context),
                          icon: Icons.block_rounded,
                        )
                      : _List(state: state),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _List extends StatelessWidget {
  final BlockedListState state;
  const _List({required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s20,
        vertical: QeranSpacing.s16,
      ),
      itemCount: state.users.length,
      separatorBuilder: (_, _) => QeranSpacing.vs12,
      itemBuilder: (context, i) {
        final user = state.users[i];
        return _BlockedRow(
          user: user,
          unblocking: state.unblockingId == user.userId,
          onUnblock: state.unblockingId != null
              ? null
              : () => context.read<BlockedListCubit>().unblock(user.userId),
        );
      },
    );
  }
}

class _BlockedRow extends StatelessWidget {
  final BlockedUser user;
  final bool unblocking;
  final VoidCallback? onUnblock;

  const _BlockedRow({
    required this.user,
    required this.unblocking,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        QeranMonogram(name: user.name, size: 44),
        QeranSpacing.hs12,
        Expanded(
          child: Text(
            user.name.isEmpty ? '—' : user.name,
            style: QeranTypography.body.copyWith(color: QeranColors.inkStrong),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        QeranSpacing.hs12,
        SizedBox(
          width: 110,
          child: QeranButton(
            label: LocaleKeys.block_action_unblock.t(context),
            variant: QeranButtonVariant.secondary,
            size: QeranButtonSize.sm,
            loading: unblocking,
            onPressed: onUnblock,
          ),
        ),
      ],
    );
  }
}
