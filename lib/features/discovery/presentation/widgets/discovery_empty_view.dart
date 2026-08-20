import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'discovery_empty_branch.dart';

/// Shown when the deck is empty (`profiles.isEmpty`) or exhausted
/// (`currentIndex >= profiles.length`) with no page left to fetch.
///
/// These situations must not read the same, because the remedy differs:
/// * **Seen everyone** — the user consumed the whole deck. Nothing is wrong;
///   more people just have to join. Refreshing is the honest action.
/// * **Filters matched nobody** — the query is the problem, so the filter sheet
///   is the way out. Without it this is a DEAD END: the filter button lives on
///   the card photo, and there is no card.
/// * **Both at once** — the filter matched nobody NEW and everyone it did match
///   is already seen. Two legitimate remedies, so both are offered.
/// * **Neither** — nothing known. Falls back to the long-standing generic copy
///   rather than guessing at a cause.
class DiscoveryEmptyView extends StatelessWidget {
  const DiscoveryEmptyView({
    super.key,
    this.seenEveryone = false,
    this.filtersMatchedNobody = false,
    this.onRefresh,
    this.onEditFilters,
    this.onStartOver,
    this.startingOver = false,
  });

  /// The user has seen every profile this query can offer — reported by the
  /// server, inferred by the client, or both.
  final bool seenEveryone;

  /// The server reported that the active filters matched nobody at all.
  final bool filtersMatchedNobody;

  /// Re-fetches the deck from page 1. Honest by design: if nobody new has
  /// joined, this same view comes back.
  final VoidCallback? onRefresh;

  /// Reopens the filter sheet, seeded with what is applied.
  final VoidCallback? onEditFilters;

  /// Restores the profiles the user skipped, so they return to the deck.
  /// Likes are untouched — server-side this clears skipped rows only.
  ///
  /// Offered by every branch that can tell the user they have seen everyone.
  /// Null simply drops the action, like every other handler here.
  final VoidCallback? onStartOver;

  /// Drives the button's own disable + spinner treatment while the reset is in
  /// flight. Deliberately not offered for [onRefresh]: a refresh moves the
  /// cubit to `DiscoveryLoading`, which replaces this whole view with the card
  /// skeleton, so a spinner here could never be seen.
  final bool startingOver;

  DiscoveryEmptyBranch get _branch => DiscoveryEmptyBranch.resolve(
    seenEveryone: seenEveryone,
    filtersMatchedNobody: filtersMatchedNobody,
  );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QeranSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_branch.icon, size: 72, color: QeranColors.inkMuted),
            const SizedBox(height: QeranSpacing.s16),
            Text(
              _branch.titleKey.t(context),
              style: QeranTypography.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: QeranSpacing.s8),
            Text(
              _branch.messageKey.t(context),
              style: QeranTypography.body.copyWith(color: QeranColors.inkMuted),
              textAlign: TextAlign.center,
            ),
            ..._actions(context),
          ],
        ),
      ),
    );
  }

  /// One rule, no exceptions: an action whose handler is null is not rendered.
  /// A caller that cannot service a button must not be able to paint one.
  ///
  /// Exactly one primary per branch. "Start over" is offered wherever the user
  /// has seen everyone — which is both branches that can say so — and takes
  /// whichever rank is left once the branch's own remedy has the primary slot.
  List<Widget> _actions(BuildContext context) {
    final actions = <Widget>[];
    switch (_branch) {
      case DiscoveryEmptyBranch.seenAll:
        if (onRefresh != null) {
          actions.add(
            QeranButton(
              label: LocaleKeys.discovery_empty_seen_all_cta_refresh.t(context),
              leadingIcon: Icons.refresh_rounded,
              onPressed: onRefresh,
              variant: QeranButtonVariant.primaryGold,
              fullWidth: false,
            ),
          );
        }
        _addIfAny(actions, _startOver(context, QeranButtonVariant.ghost));
      case DiscoveryEmptyBranch.filtered:
        if (onEditFilters != null) {
          actions.add(_editFilters(context, QeranButtonVariant.primaryGold));
        }
      case DiscoveryEmptyBranch.both:
        final startOver = _startOver(context, QeranButtonVariant.primaryGold);
        _addIfAny(actions, startOver);
        if (onEditFilters != null) {
          // Falls back to primary when there is no reset to outrank it, so the
          // branch is never left with a lone ghost button.
          actions.add(
            _editFilters(
              context,
              startOver == null
                  ? QeranButtonVariant.primaryGold
                  : QeranButtonVariant.ghost,
            ),
          );
        }
      case DiscoveryEmptyBranch.generic:
        break;
    }
    if (actions.isEmpty) return const [];
    return [
      const SizedBox(height: QeranSpacing.s24),
      for (final (i, action) in actions.indexed) ...[
        if (i > 0) const SizedBox(height: QeranSpacing.s8),
        action,
      ],
    ];
  }

  void _addIfAny(List<Widget> actions, Widget? action) {
    if (action != null) actions.add(action);
  }

  /// Null when there is no reset to run, so the caller simply gets one fewer
  /// action rather than an inert one.
  Widget? _startOver(BuildContext context, QeranButtonVariant variant) {
    if (onStartOver == null) return null;
    return QeranButton(
      label: LocaleKeys.discovery_empty_start_over.t(context),
      leadingIcon: Icons.restart_alt_rounded,
      onPressed: onStartOver,
      loading: startingOver,
      variant: variant,
      size: variant == QeranButtonVariant.ghost
          ? QeranButtonSize.md
          : QeranButtonSize.lg,
      fullWidth: false,
    );
  }

  Widget _editFilters(BuildContext context, QeranButtonVariant variant) {
    return QeranButton(
      label: LocaleKeys.discovery_empty_edit_filters.t(context),
      leadingIcon: Icons.tune_rounded,
      onPressed: onEditFilters,
      variant: variant,
      size: variant == QeranButtonVariant.ghost
          ? QeranButtonSize.md
          : QeranButtonSize.lg,
      fullWidth: false,
    );
  }
}
