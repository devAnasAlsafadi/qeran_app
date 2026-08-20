import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Which terminal state the deck landed in. The two inputs are INDEPENDENT —
/// the server reporting that a query matched nobody, and the client having
/// watched the user swipe past the last card — so all four combinations are
/// reachable and each gets its own copy.
enum _EmptyBranch { seenAll, filtered, both, generic }

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

  /// Clears the server-side seen history so previously-shown profiles return.
  /// Null while the endpoint is unavailable — the button still renders, but
  /// [QeranButton] paints it disabled.
  final VoidCallback? onStartOver;

  /// Drives the button's own disable + spinner treatment while the reset is in
  /// flight. Deliberately not offered for [onRefresh]: a refresh moves the
  /// cubit to `DiscoveryLoading`, which replaces this whole view with the card
  /// skeleton, so a spinner here could never be seen.
  final bool startingOver;

  _EmptyBranch get _branch {
    if (seenEveryone && filtersMatchedNobody) return _EmptyBranch.both;
    if (filtersMatchedNobody) return _EmptyBranch.filtered;
    if (seenEveryone) return _EmptyBranch.seenAll;
    return _EmptyBranch.generic;
  }

  IconData get _icon => switch (_branch) {
    // Completion, not absence — the user did not hit a wall, they finished.
    _EmptyBranch.seenAll => Icons.done_all_rounded,
    _EmptyBranch.filtered || _EmptyBranch.both => Icons.filter_alt_off_outlined,
    _EmptyBranch.generic => Icons.people_outline_rounded,
  };

  String get _titleKey => switch (_branch) {
    _EmptyBranch.seenAll => LocaleKeys.discovery_empty_seen_all_title,
    // The filter is the more actionable of the two problems, so it leads.
    _EmptyBranch.filtered ||
    _EmptyBranch.both => LocaleKeys.discovery_empty_filtered_title,
    _EmptyBranch.generic => LocaleKeys.discovery_empty_title,
  };

  String get _messageKey => switch (_branch) {
    _EmptyBranch.seenAll => LocaleKeys.discovery_empty_seen_all_message,
    _EmptyBranch.filtered => LocaleKeys.discovery_empty_filtered_subtitle,
    _EmptyBranch.both =>
      LocaleKeys.discovery_empty_filtered_seen_all_message,
    _EmptyBranch.generic => LocaleKeys.discovery_empty_subtitle,
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QeranSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 72, color: QeranColors.inkMuted),
            const SizedBox(height: QeranSpacing.s16),
            Text(
              _titleKey.t(context),
              style: QeranTypography.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: QeranSpacing.s8),
            Text(
              _messageKey.t(context),
              style: QeranTypography.body.copyWith(color: QeranColors.inkMuted),
              textAlign: TextAlign.center,
            ),
            ..._actions(context),
          ],
        ),
      ),
    );
  }

  /// One primary per branch. A handler-less action is not rendered at all —
  /// a caller that cannot service a button must not be able to paint a dead
  /// one. [onStartOver] is the deliberate exception; see its doc.
  List<Widget> _actions(BuildContext context) {
    final actions = <Widget>[];
    switch (_branch) {
      case _EmptyBranch.seenAll:
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
      case _EmptyBranch.filtered:
        if (onEditFilters != null) {
          actions.add(_editFilters(context, QeranButtonVariant.primaryGold));
        }
      case _EmptyBranch.both:
        // Rendered even with a null handler, which QeranButton paints disabled.
        // BLOCKED ON BACKEND: reset-seen currently clears likes and passes too,
        // and a like is a pending proposal someone may be waiting on. The call
        // stays unwired until that endpoint clears only the seen history.
        actions.add(
          QeranButton(
            label: LocaleKeys.discovery_empty_start_over.t(context),
            leadingIcon: Icons.restart_alt_rounded,
            onPressed: onStartOver,
            loading: startingOver,
            variant: QeranButtonVariant.primaryGold,
            fullWidth: false,
          ),
        );
        if (onEditFilters != null) {
          actions.add(_editFilters(context, QeranButtonVariant.ghost));
        }
      case _EmptyBranch.generic:
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
