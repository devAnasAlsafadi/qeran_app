import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../../core/design_system/tokens/qeran_radii.dart';
import '../../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../../core/design_system/widgets/qeran_bottom_sheet.dart';
import '../../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_text_field.dart';
import '../../../../../core/enum/snakebar_tybe.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/utils/app_snackbar.dart';
import '../../../../../core/di/injection_container.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_user_avatar.dart';
import '../../../users/domain/entities/matchmaker_user_row.dart';
import '../blocs/share/matchmaker_share_cubit.dart';
import '../blocs/share/matchmaker_share_state.dart';

/// Recipient picker (10) — shares the browsed profile [sharedUserId] into the
/// chats of the matchmaker's OWN approved users (multi-select). The optional
/// candidate context (name/age/image) renders a "who am I sending" card so she
/// never sends the wrong person. Self-contained: owns its [MatchmakerShareCubit].
Future<void> showMatchmakerShareSheet(
  BuildContext context, {
  required String sharedUserId,
  String? candidateName,
  int? candidateAge,
  String? candidateImageUrl,
}) {
  return showQeranBottomSheet<void>(
    context: context,
    builder: (_) => BlocProvider<MatchmakerShareCubit>(
      create: (_) =>
          sl<MatchmakerShareCubit>(param1: sharedUserId)..loadFirst(),
      child: _ShareSheet(
        candidateName: candidateName,
        candidateAge: candidateAge,
        candidateImageUrl: candidateImageUrl,
      ),
    ),
  );
}

class _ShareSheet extends StatefulWidget {
  const _ShareSheet({
    this.candidateName,
    this.candidateAge,
    this.candidateImageUrl,
  });

  final String? candidateName;
  final int? candidateAge;
  final String? candidateImageUrl;

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  String _query = '';

  /// Set true once a full send succeeds — swaps in the confirmation, then the
  /// sheet auto-closes.
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
      context.read<MatchmakerShareCubit>().loadMore();
    }
  }

  Future<void> _onOutcome(
    BuildContext context,
    MatchmakerShareState state,
  ) async {
    final n = '${state.sharedCount}';
    final m = '${state.totalCount}';
    switch (state.outcome) {
      case ShareSendOutcome.success:
        // In-sheet confirmation, then auto-close with a toast.
        setState(() => _success = true);
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        if (!mounted) return;
        Navigator.of(this.context).pop();
        AppSnackBar.showOnRoot(
          message: LocaleKeys.matchmaker_explore_share_success
              .t(this.context)
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
      child: QeranBottomSheetScaffold(
        title: LocaleKeys.matchmaker_explore_share_title.t(context),
        body: _success ? const _SuccessView() : _body(),
        footer: _success ? null : const _Footer(),
      ),
    );
  }

  Widget _body() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        if (widget.candidateName != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              QeranSpacing.s20,
              0,
              QeranSpacing.s20,
              QeranSpacing.s12,
            ),
            child: _CandidateCard(
              name: widget.candidateName!,
              age: widget.candidateAge,
              imageUrl: widget.candidateImageUrl,
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: QeranSpacing.s20),
          child: QeranTextField(
            controller: _search,
            hint: LocaleKeys.matchmaker_explore_share_search_hint.t(context),
            prefix: const Icon(
              Icons.search_rounded,
              size: 20,
              color: QeranColors.inkMuted,
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        const _CountLine(),
        Expanded(child: _List(scroll: _scroll, query: _query)),
      ],
    );
  }
}

/// The "who is being shared" card — cream-surface + gold-40, monogram + name +
/// age. Nationality is not a structured field, so it is intentionally omitted.
class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.name, this.age, this.imageUrl});

  final String name;
  final int? age;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(QeranSpacing.s12),
      decoration: BoxDecoration(
        color: QeranColors.creamSurface,
        borderRadius: QeranRadii.cardR,
        border: Border.all(color: QeranColors.gold40),
      ),
      child: Row(
        children: [
          MatchmakerUserAvatar(url: imageUrl, size: 48, monogramName: name),
          QeranSpacing.hs12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: QeranTypography.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (age != null) ...[
                  QeranSpacing.vs4,
                  Text(
                    context.tr(
                      LocaleKeys.matchmaker_users_age_years,
                      namedArgs: {'age': '$age'},
                    ),
                    style: QeranTypography.caption,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "تم اختيار {n}" — the live selection count in gold-deep.
class _CountLine extends StatelessWidget {
  const _CountLine();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerShareCubit, MatchmakerShareState>(
      buildWhen: (a, b) => a.selectedCount != b.selectedCount,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            QeranSpacing.s20,
            QeranSpacing.s8,
            QeranSpacing.s20,
            QeranSpacing.s4,
          ),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              context.tr(
                LocaleKeys.matchmaker_explore_share_selected,
                namedArgs: {'count': '${state.selectedCount}'},
              ),
              style: QeranTypography.label.copyWith(
                color: QeranColors.goldDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.scroll, required this.query});

  final ScrollController scroll;
  final String query;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MatchmakerShareCubit, MatchmakerShareState>(
      builder: (context, state) {
        if (state.loading) return const _ShareSkeleton();
        if (state.errorMessage != null && state.recipients.isEmpty) {
          return QeranErrorState(
            title: LocaleKeys.matchmaker_explore_share_error.t(context),
            message: state.errorMessage!.t(context),
            retryLabel: LocaleKeys.matchmaker_explore_retry.t(context),
            onRetry: () => context.read<MatchmakerShareCubit>().loadFirst(),
          );
        }
        if (state.recipients.isEmpty) {
          return QeranEmptyState(
            icon: Icons.group_off_outlined,
            title: LocaleKeys.matchmaker_explore_share_empty.t(context),
          );
        }
        final visible = query.isEmpty
            ? state.recipients
            : state.recipients
                .where((r) => r.fullName.toLowerCase().contains(query))
                .toList(growable: false);
        if (visible.isEmpty) {
          return const Center(
            child: Icon(
              Icons.search_off_rounded,
              size: 40,
              color: QeranColors.inkFaint,
            ),
          );
        }
        return ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.symmetric(
            horizontal: QeranSpacing.s12,
            vertical: QeranSpacing.s8,
          ),
          itemCount: visible.length + (state.loadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= visible.length) {
              return const Padding(
                padding: EdgeInsets.all(QeranSpacing.s16),
                child: _ShareSkeletonRow(),
              );
            }
            final row = visible[index];
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
            QeranSpacing.s20,
            QeranSpacing.s8,
            QeranSpacing.s20,
            QeranSpacing.s16,
          ),
          child: Row(
            children: [
              Expanded(
                child: QeranButton(
                  label: LocaleKeys.common_cancel.t(context),
                  variant: QeranButtonVariant.ghost,
                  onPressed: state.sending
                      ? null
                      : () => Navigator.of(context).pop(),
                ),
              ),
              QeranSpacing.hs12,
              Expanded(
                flex: 2,
                child: QeranButton(
                  label: context.tr(
                    LocaleKeys.matchmaker_explore_share_send,
                    namedArgs: {'count': '$count'},
                  ),
                  variant: QeranButtonVariant.primary,
                  leadingIcon: Icons.send_rounded,
                  loading: state.sending,
                  onPressed: (count == 0 || state.sending)
                      ? null
                      : () => context.read<MatchmakerShareCubit>().send(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One selectable recipient — avatar + name + age, with a token select control
/// (gold disc + wine check when selected; wine-20 ring otherwise).
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
            MatchmakerUserAvatar(
              url: row.profileImageUrl,
              size: 44,
              monogramName: row.fullName,
            ),
            QeranSpacing.hs12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    row.fullName,
                    style: QeranTypography.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (row.age != null) ...[
                    QeranSpacing.vs4,
                    Text(
                      context.tr(
                        LocaleKeys.matchmaker_users_age_years,
                        namedArgs: {'age': '${row.age}'},
                      ),
                      style: QeranTypography.caption,
                    ),
                  ],
                ],
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
        color: selected ? QeranColors.gold : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? QeranColors.gold : QeranColors.wine20,
          width: 1.5,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 16, color: QeranColors.wine)
          : null,
    );
  }
}

/// The in-sheet success confirmation — a gold check + "تمت المشاركة".
class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(QeranSpacing.s48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: QeranColors.gold,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.check_rounded,
              size: 34,
              color: QeranColors.wine,
            ),
          ),
          QeranSpacing.vs16,
          Text(
            LocaleKeys.matchmaker_explore_share_done.t(context),
            style: QeranTypography.title,
          ),
        ],
      ),
    );
  }
}

/// Skeleton rows shown while her users load.
class _ShareSkeleton extends StatelessWidget {
  const _ShareSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s8,
      ),
      children: const [
        _ShareSkeletonRow(),
        _ShareSkeletonRow(),
        _ShareSkeletonRow(),
        _ShareSkeletonRow(),
        _ShareSkeletonRow(),
        _ShareSkeletonRow(),
      ],
    );
  }
}

class _ShareSkeletonRow extends StatelessWidget {
  const _ShareSkeletonRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: QeranSpacing.s12,
        vertical: QeranSpacing.s8,
      ),
      child: Row(
        children: [
          _Box(width: 44, height: 44, radius: 22),
          QeranSpacing.hs12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Box(width: 140, height: 12, radius: 6),
                SizedBox(height: QeranSpacing.s8),
                _Box(width: 80, height: 10, radius: 5),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.width, required this.height, required this.radius});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: QeranColors.creamSurface,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
