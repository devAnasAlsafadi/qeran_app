import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/widgets/qeran_page_indicator.dart';

import '../../domain/entities/match_image.dart';
import '../blocs/photo_view_state.dart';
import 'match_photo_page.dart';
import 'photo_view_access_host.dart';

/// Full-bleed, swipeable viewer for the compatibility gallery.
///
/// **It lives INSIDE [PhotoViewScope], and that is the whole point.** The
/// surface it replaces was a route pushed ABOVE the scope, so the policy could
/// not reach it and was re-wired by hand — `memoryOnly` passed explicitly, an
/// expiry listener bolted on, and the grid tile refusing to open a blurred
/// photo. That last guard is the one a pager cannot keep: a second photo is
/// reached by swiping, not by a tap something can refuse.
///
/// So the policy is inherited, not copied: [MatchPhotoPage] builds its photo
/// with **no** explicit policy arguments, which is what applies
/// `effectiveBlur`, `blockImageBytes`, `memoryOnly` and `onImageForbidden` to
/// every page — including ones not swiped to yet.
///
/// Differs from the old route in two ways: concealing now reaches the open
/// viewer (it blurs in place), and the window ending closes it via [onClose]
/// rather than popping a route, since there is no route to pop.
///
/// Swipe only — no arrows. `PageView` mirrors itself under RTL, so nothing
/// here flips an index by hand.
class MatchPhotoPager extends StatefulWidget {
  const MatchPhotoPager({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.onClose,
  });

  final List<MatchImage> images;

  /// Page to open on — the tile the member tapped.
  final int initialIndex;

  /// Dismissal, from the × or the system back gesture. Also fired when the
  /// viewing window ends, so the viewer cannot outlive the access that opened
  /// it.
  final VoidCallback onClose;

  @override
  State<MatchPhotoPager> createState() => _MatchPhotoPagerState();
}

class _MatchPhotoPagerState extends State<MatchPhotoPager> {
  late final PageController _controller;
  late int _index;

  /// The close is fired once. Without this a rebuild storm at expiry (state,
  /// then conceal, then the refetch) would queue several callbacks.
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, _lastIndex);
    _controller = PageController(initialPage: _index);
  }

  int get _lastIndex => widget.images.isEmpty ? 0 : widget.images.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The scope is an [InheritedWidget], so a policy change lands here. Closes
  /// when the WINDOW ENDS, not when it merely conceals: a member who glances at
  /// another app during their one opening should find the photos where they
  /// left them (blurred meanwhile, by the same policy), not be ejected.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final access = PhotoViewScope.maybeOf(context);
    if (access == null || !access.controlsAccess) return;
    if (access.state.phase == PhotoViewPhase.viewing) return;
    _closeOnce();
  }

  void _closeOnce() {
    if (_closing) return;
    _closing = true;
    // Never during a build — this can be reached from didChangeDependencies.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();
    return PopScope(
      // The viewer is a layer, not a route, so back has nothing to pop on its
      // own — it is routed to the same close the × uses.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onClose();
      },
      child: ColoredBox(
        color: QeranColors.wine,
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(child: _pages()),
              PositionedDirectional(
                top: QeranSpacing.s8,
                // START, clear of the × opposite it.
                start: QeranSpacing.s12,
                child: QeranPageCounter(
                  index: _index + 1,
                  total: widget.images.length,
                ),
              ),
              PositionedDirectional(
                top: QeranSpacing.s8,
                end: QeranSpacing.s8,
                child: _CloseButton(onTap: widget.onClose),
              ),
              if (widget.images.length > 1)
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: QeranSpacing.s16,
                  child: QeranPageDots(
                    count: widget.images.length,
                    current: _index,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pages() {
    return PageView.builder(
      controller: _controller,
      onPageChanged: (i) => setState(() => _index = i),
      itemCount: widget.images.length,
      itemBuilder: (_, i) => MatchPhotoPage(
        // Keyed on the image id, not the index: it addresses one page whether
        // or not it is the visible one, which is what lets a test assert that
        // an OFF-SCREEN page obeys the policy too.
        key: ValueKey<String>('match-photo-page-${widget.images[i].id}'),
        image: widget.images[i],
        // Leaving a page resets its zoom, so every page is framed the same way
        // each time it is reached.
        isActive: i == _index,
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: QeranColors.wine80,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.close_rounded, color: QeranColors.paper, size: 22),
        ),
      ),
    );
  }
}
