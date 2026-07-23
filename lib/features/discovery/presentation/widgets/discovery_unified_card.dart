import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';

import '../../domain/entities/discovery_profile.dart';
import '../blocs/discovery_cubit.dart';
import 'discovery_card.dart';
import 'discovery_deck_animator.dart';
import 'discovery_swipe_handler.dart';

/// The unified discovery card: one rounded block whose top ~54 % is the
/// FIXED blurred photo (name / age / chips overlaid) and whose bottom is a
/// white surface hosting the نبذة عني preview + inside chips that scrolls
/// INTERNALLY. The photo never scrolls and the page itself doesn't scroll —
/// only this inner data region does.
///
/// The deck-animator → swipe-handler → content nesting is kept identical to
/// the previous image card, so horizontal like / pass / undo / eject and the
/// peek-deck coupling behave exactly as before. The inner vertical scroll and
/// the outer horizontal swipe are disambiguated by the gesture arena (dominant
/// axis wins), so the swipe handler stays untouched.
class DiscoveryUnifiedCard extends StatelessWidget {
  final DiscoveryProfile profile;
  final VoidCallback onTapDetails;

  /// Bottom padding inside the scroll so the last chips clear the floating
  /// action cluster / bottom nav.
  final double bottomContentInset;

  const DiscoveryUnifiedCard({
    super.key,
    required this.profile,
    required this.onTapDetails,
    required this.bottomContentInset,
  });

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey<String>(profile.id),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) => Transform.translate(
          offset: Offset(0, 8 * (1 - progress)),
          child: child,
        ),
        child: DiscoveryDeckAnimator(
          child: DiscoverySwipeHandler(
            // The animator transforms this cached card layer as a whole. The
            // expensive blurred image no longer repaints on every drag tick.
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: QeranRadii.panelR,
                  color: QeranColors.paper,
                  border: Border.all(
                    color: QeranColors.wine.withValues(alpha: 0.10),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: QeranColors.wine.withValues(alpha: 0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: QeranRadii.panelR,
                  child: _CardContent(
                    profile: profile,
                    onTapDetails: onTapDetails,
                    bottomContentInset: bottomContentInset,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  final DiscoveryProfile profile;
  final VoidCallback onTapDetails;
  final double bottomContentInset;

  const _CardContent({
    required this.profile,
    required this.onTapDetails,
    required this.bottomContentInset,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        return Flex(
          direction: isLandscape ? Axis.horizontal : Axis.vertical,
          children: [
            // FIXED photo — top slice of the card. Tapping it opens the full
            // profile (unchanged navigation).
            Expanded(
              flex: isLandscape ? 45 : 54,
              child: DiscoveryImagePanel(
                profile: profile,
                onTap: onTapDetails,
                showOverlayActions: false,
              ),
            ),
            // Internal scroll region on the white surface. Pull-to-refresh keeps
            // the exact same DiscoveryCubit.refresh() wiring, re-hosted here.
            Expanded(
              flex: isLandscape ? 55 : 46,
              child: ColoredBox(
                color: QeranColors.paper,
                child: RefreshIndicator(
                  color: QeranColors.wine,
                  onRefresh: () => context.read<DiscoveryCubit>().refresh(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      QeranSpacing.s20,
                      QeranSpacing.s20,
                      QeranSpacing.s20,
                      isLandscape ? QeranSpacing.s24 : bottomContentInset,
                    ),
                    child: DiscoveryInfoPanel(profile: profile),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
