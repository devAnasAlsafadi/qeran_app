import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';

import '../../domain/entities/discovery_profile.dart';
import '../blocs/discovery_cubit.dart';
import '../blocs/discovery_hydration_cubit.dart';
import '../blocs/discovery_state.dart';
import 'discovery_blurred_image.dart';
import 'discovery_card_skeleton.dart';
import 'discovery_unified_card.dart';
import 'open_discovery_filters.dart';

/// Height reserved at the end of the scroll so the last section and the share
/// CTA can travel clear of the pinned frosted action cluster.
const double _kActionZoneClearance = 128.0;

/// The loaded discovery feed: one full-bleed [DiscoveryUnifiedCard] filling
/// the viewport. No peek layer — a full-screen surface has nothing to peek
/// out from behind it; the swipe replaces the surface wholesale.
class DiscoveryProfilePage extends StatefulWidget {
  final DiscoveryLoaded loaded;
  final ValueNotifier<double> scrollOffset;
  const DiscoveryProfilePage({
    super.key,
    required this.loaded,
    required this.scrollOffset,
  });

  @override
  State<DiscoveryProfilePage> createState() => _DiscoveryProfilePageState();
}

class _DiscoveryProfilePageState extends State<DiscoveryProfilePage> {
  String? _precachedNextProfileId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleNextPhotoPrecache();
    _hydrateCurrent();
  }

  @override
  void didUpdateWidget(covariant DiscoveryProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loaded.next?.id != widget.loaded.next?.id) {
      _scheduleNextPhotoPrecache();
    }
    if (oldWidget.loaded.current?.id != widget.loaded.current?.id) {
      _hydrateCurrent();
    }
  }

  /// Fetches the current card's full profile so the below-the-fold sections
  /// are already in place by the time the user scrolls to them — no spinner
  /// on a scroll, and no fetch storm while swiping quickly. Cached by id, so
  /// undo never refetches.
  void _hydrateCurrent() {
    final current = widget.loaded.current;
    if (current == null) return;
    context.read<DiscoveryHydrationCubit>().hydrate(current.id);
  }

  void _scheduleNextPhotoPrecache() {
    final next = widget.loaded.next;
    if (next == null || next.id == _precachedNextProfileId) return;
    final imageUrl = _primaryImageUrl(next);
    if (imageUrl.isEmpty) return;
    _precachedNextProfileId = next.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(precacheDiscoveryPhoto(context, imageUrl));
    });
  }

  String _primaryImageUrl(DiscoveryProfile profile) {
    if (profile.images.isEmpty) return '';
    return profile.images
        .firstWhere(
          (image) => image.isProfile,
          orElse: () => profile.images.first,
        )
        .url;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final navClearance =
            QeranBottomNav.contentClearance(context) +
            (isLandscape ? 12.0 : 24.0);
        final profile = widget.loaded.current!;
        // constraints.maxHeight is already the area below the shell's top
        // bar, so this is the visible viewport — the same height the first
        // screenful is padded out to.
        final viewportHeight = constraints.maxHeight;
        // Landscape has far less height to spend, so the photo takes a
        // smaller share and the profile starts sooner; a small phone held
        // upright gets a fixed height instead of half.
        final photoHeight = discoveryPhotoHeight(
          context,
          viewportHeight: viewportHeight,
          isLandscape: isLandscape,
        );

        // Zero left/right margins: the surface is the screen. The bottom
        // clearance lives INSIDE the scroll so content can travel past the
        // action cluster instead of being boxed above it.
        return DiscoveryUnifiedCard(
          profile: profile,
          viewportHeight: viewportHeight,
          photoHeight: photoHeight,
          bottomInset: navClearance + _kActionZoneClearance,
          scrollOffset: widget.scrollOffset,
          onFilterTap: () => openDiscoveryFilters(context),
          activeFilterCount: context.read<DiscoveryCubit>().activeFilters.count,
        );
      },
    );
  }
}
