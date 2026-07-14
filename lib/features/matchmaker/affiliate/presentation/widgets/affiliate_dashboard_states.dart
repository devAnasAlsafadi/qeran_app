import 'package:flutter/material.dart';

import '../../../../../core/design_system/widgets/qeran_empty_state.dart';
import '../../../../../core/design_system/widgets/qeran_error_state.dart';
import '../../../../../core/design_system/widgets/qeran_loader.dart';
import '../../../../../core/extensions/localization_extension.dart';
import '../../../../../core/state/paginated_list_state.dart';
import '../../../../../generated/locale_keys.g.dart';
import '../../../shared/presentation/widgets/matchmaker_paginated_list.dart';
import '../../domain/entities/affiliate_commission.dart';
import '../blocs/affiliate_commissions_cubit.dart';

/// The ledger area when there are no rows: first-load spinner, a retryable
/// error, or the calm empty-ledger state (enrolled but nothing yet). Rendered
/// below the dashboard header inside a bounded box.
class AffiliateLedgerPlaceholder extends StatelessWidget {
  const AffiliateLedgerPlaceholder({
    super.key,
    required this.state,
    required this.cubit,
  });

  final PaginatedListState<AffiliateCommission> state;
  final AffiliateCommissionsCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: QeranLoader());
    }
    if (state.errorMessage != null) {
      return QeranErrorState(
        title: LocaleKeys.matchmaker_affiliate_error_title.t(context),
        message: state.errorMessage!.t(context),
        retryLabel: LocaleKeys.matchmaker_users_retry.t(context),
        onRetry: cubit.loadFirst,
      );
    }
    return QeranEmptyState(
      icon: Icons.receipt_long_outlined,
      title: LocaleKeys.matchmaker_affiliate_ledger_empty_title.t(context),
      message: LocaleKeys.matchmaker_affiliate_ledger_empty_message.t(context),
    );
  }
}

/// Full-viewport, pull-to-refreshable wrapper that centers a single [child]
/// (empty / error surface) while keeping the scroll gesture alive. Mirrors the
/// colleagues directory's empty-state pattern.
class AffiliateRefreshableCentered extends StatelessWidget {
  const AffiliateRefreshableCentered({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MatchmakerPaginatedList(
      hasMore: false,
      onRefresh: onRefresh,
      onLoadMore: () async {},
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ),
      ),
    );
  }
}
