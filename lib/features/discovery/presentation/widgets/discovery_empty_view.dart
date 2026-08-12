import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Shown when the deck is empty (`profiles.isEmpty`) or exhausted
/// (`currentIndex >= profiles.length`).
///
/// Two different situations, and they must not read the same:
/// * **No filters** — there is genuinely nobody left right now. Nothing for the
///   user to do but come back later.
/// * **Filters applied** — the filter narrowed the deck to nothing. This state
///   is a DEAD END without a way out: the filter button lives on the card
///   photo, and there is no card, so the only escape was killing the app. Hence
///   the two actions.
class DiscoveryEmptyView extends StatelessWidget {
  const DiscoveryEmptyView({
    super.key,
    this.hasFilters = false,
    this.onEditFilters,
    this.onClearFilters,
    this.canReplay = false,
    this.onReplay,
  });

  /// Whether a filter is currently constraining the deck.
  final bool hasFilters;

  /// Reopens the filter sheet, seeded with what is applied.
  final VoidCallback? onEditFilters;

  /// Drops every filter and reloads the unconstrained deck.
  final VoidCallback? onClearFilters;

  /// A non-filtered deck can be exhausted while still retaining the profiles
  /// it showed in memory. Offer a local replay instead of a dead end.
  final bool canReplay;
  final VoidCallback? onReplay;

  bool get _showActions =>
      hasFilters && onEditFilters != null && onClearFilters != null;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(QeranSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFilters
                  ? Icons.filter_alt_off_outlined
                  : Icons.people_outline_rounded,
              size: 72,
              color: QeranColors.inkMuted,
            ),
            const SizedBox(height: QeranSpacing.s16),
            Text(
              (hasFilters
                      ? LocaleKeys.discovery_empty_filtered_title
                      : LocaleKeys.discovery_empty_title)
                  .t(context),
              style: QeranTypography.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: QeranSpacing.s8),
            Text(
              (hasFilters
                      ? LocaleKeys.discovery_empty_filtered_subtitle
                      : LocaleKeys.discovery_empty_subtitle)
                  .t(context),
              style: QeranTypography.body.copyWith(color: QeranColors.inkMuted),
              textAlign: TextAlign.center,
            ),
            if (_showActions) ...[
              const SizedBox(height: QeranSpacing.s24),
              QeranButton(
                label: LocaleKeys.discovery_empty_edit_filters.t(context),
                leadingIcon: Icons.tune_rounded,
                onPressed: onEditFilters,
                fullWidth: false,
              ),
              const SizedBox(height: QeranSpacing.s8),
              QeranButton(
                label: LocaleKeys.discovery_empty_clear_filters.t(context),
                onPressed: onClearFilters,
                variant: QeranButtonVariant.ghost,
                size: QeranButtonSize.md,
                fullWidth: false,
              ),
            ] else if (canReplay && onReplay != null) ...[
              const SizedBox(height: QeranSpacing.s24),
              QeranButton(
                label: LocaleKeys.discovery_empty_replay.t(context),
                leadingIcon: Icons.replay_rounded,
                onPressed: onReplay,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
