import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_shadows.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/design_system/widgets/qeran_sheet_handle.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../../../users/domain/entities/matchmaker_user_row.dart';
import '../blocs/share/matchmaker_share_cubit.dart';
import '../blocs/share/matchmaker_share_state.dart';

/// Recipient picker for sharing the browsed profile [sharedUserId] with the
/// matchmaker's OWN approved users (multi-select). Self-contained: creates its
/// own [MatchmakerShareCubit] and loads on open. Send is wired in a later step.
Future<void> showMatchmakerShareSheet(
  BuildContext context, {
  required String sharedUserId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: QeranColors.overlayTintDark,
    useSafeArea: true,
    builder: (_) => BlocProvider<MatchmakerShareCubit>(
      create: (_) =>
          sl<MatchmakerShareCubit>(param1: sharedUserId)..loadFirst(),
      child: const _ShareSheet(),
    ),
  );
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet();

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      context.read<MatchmakerShareCubit>().loadMore();
    }
  }

  /// One-shot send result → toast + close on any success (full or partial);
  /// full failure keeps the sheet open so she can retry.
  void _onOutcome(BuildContext context, MatchmakerShareState state) {
    final n = '${state.sharedCount}';
    final m = '${state.totalCount}';
    switch (state.outcome) {
      case ShareSendOutcome.success:
        Navigator.of(context).pop();
        AppSnackBar.showOnRoot(
          message: LocaleKeys.matchmaker_explore_share_success
              .t(context)
              .replaceFirst('{n}', n),
          type: SnackBarType.success,
        );
      case ShareSendOutcome.partial:
        Navigator.of(context).pop();
        AppSnackBar.showOnRoot(
          message: LocaleKeys.matchmaker_explore_share_partial
              .t(context)
              .replaceFirst('{n}', n)
              .replaceFirst('{m}', m),
          type: SnackBarType.notice,
        );
      case ShareSendOutcome.failure:
        AppSnackBar.showOnRoot(
          message: LocaleKeys.matchmaker_explore_share_failed.t(context),
          type: SnackBarType.error,
        );
      case ShareSendOutcome.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MatchmakerShareCubit, MatchmakerShareState>(
      listenWhen: (p, c) =>
          p.eventVersion != c.eventVersion &&
          c.outcome != ShareSendOutcome.none,
      listener: _onOutcome,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
        decoration: const BoxDecoration(
          color: QeranColors.paper,
          borderRadius: QeranRadii.domeTop,
          boxShadow: QeranShadows.e3,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: Column(
            children: [
              const QeranSheetHandle(),
              QeranSpacing.vs12,
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: QeranSpacing.s24,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        LocaleKeys.matchmaker_explore_share_title.t(context),
                        style: QeranTypography.title,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: QeranColors.wine,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(child: _Body(scroll: _scroll)),
              const _Footer(),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.scroll});

  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerShareCubit, MatchmakerShareState>(
      builder: (context, state) {
        if (state.loading) {
          return const Center(child: QeranLoader());
        }
        if (state.errorMessage != null && state.recipients.isEmpty) {
          return QeranErrorState(
            title: LocaleKeys.matchmaker_explore_share_error.t(context),
            message: state.errorMessage!.t(context),
            retryLabel: LocaleKeys.matchmaker_explore_retry.t(context),
            onRetry: () => context.read<MatchmakerShareCubit>().loadFirst(),
          );
        }
        if (state.recipients.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(QeranSpacing.s24),
              child: Text(
                LocaleKeys.matchmaker_explore_share_empty.t(context),
                textAlign: TextAlign.center,
                style:
                    QeranTypography.body.copyWith(color: QeranColors.inkMuted),
              ),
            ),
          );
        }
        return ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s12,
            vertical: QeranSpacing.s8,
          ),
          itemCount: state.recipients.length + (state.loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= state.recipients.length) {
              return const Padding(
                padding: EdgeInsets.all(QeranSpacing.s16),
                child: Center(child: QeranLoader()),
              );
            }
            final row = state.recipients[index];
            return _RecipientTile(
              row: row,
              selected: state.isSelected(row.userId),
              onTap: () =>
                  context.read<MatchmakerShareCubit>().toggle(row.userId),
            );
          },
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerShareCubit, MatchmakerShareState>(
      buildWhen: (a, b) =>
          a.selectedCount != b.selectedCount || a.sending != b.sending,
      builder: (context, state) {
        final count = state.selectedCount;
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s24,
            QeranSpacing.s8,
            QeranSpacing.s24,
            QeranSpacing.s16,
          ),
          child: QeranButton(
            label: LocaleKeys.matchmaker_explore_share_send
                .t(context)
                .replaceFirst('{count}', '$count'),
            variant: QeranButtonVariant.primaryWine,
            loading: state.sending,
            onPressed: (count == 0 || state.sending)
                ? null
                : () => context.read<MatchmakerShareCubit>().send(),
          ),
        );
      },
    );
  }
}

/// One selectable recipient — avatar + name + a token check indicator
/// (filled wine when selected, hairline ring otherwise; no Material checkbox).
class _RecipientTile extends StatelessWidget {
  const _RecipientTile({
    required this.row,
    required this.selected,
    required this.onTap,
  });

  final MatchmakerUserRow row;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: QeranRadii.controlR,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: QeranSpacing.s12,
          vertical: QeranSpacing.s8,
        ),
        child: Row(
          children: [
            MatchmakerUserAvatar(url: row.profileImageUrl, size: 44),
            QeranSpacing.hs12,
            Expanded(
              child: Text(
                row.fullName,
                style: QeranTypography.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            QeranSpacing.hs8,
            _Check(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: selected ? QeranColors.wine : QeranColors.paper,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? QeranColors.wine : QeranColors.hairline,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: QeranColors.paper)
          : null,
    );
  }
}
