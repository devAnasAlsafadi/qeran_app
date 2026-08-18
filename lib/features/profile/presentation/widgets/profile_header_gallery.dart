import 'package:flutter/material.dart';

import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/likes/presentation/widgets/like_blurred_image.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/profile_image.dart';
import 'profile_photo_hero_motion.dart';

/// Image hero for the Full Profile Details screen. A 3:4 aspect-ratio
/// PageView over the gallery (or a single primary photo) with:
///
/// * top-biased crop (`Alignment(0, -0.3)`) so faces are never clipped
///   by `BoxFit.cover` — the rule for any portrait-photo surface in a
///   matrimony product;
/// * a `1 / N` numeric pill at the top-trailing corner;
/// * a bottom-centered dots indicator (cream for unselected, gold for
///   selected) when there are multiple images;
/// * tap-to-expand into a fullscreen `InteractiveViewer` for pinch-zoom and
///   pan — offered only for photos already shown clear. A blurred photo is
///   inert: zooming a redaction has nothing to show, and this surface has no
///   way to un-redact it.
class ProfileHeaderGallery extends StatefulWidget {
  final List<ProfileImage> images;

  /// Blur every image regardless of its own flag. Set on a peer's profile,
  /// where photos never render clear whatever the exchange status says.
  final bool forceBlur;

  const ProfileHeaderGallery({
    super.key,
    required this.images,
    this.forceBlur = false,
  });

  @override
  State<ProfileHeaderGallery> createState() => _ProfileHeaderGalleryState();
}

class _ProfileHeaderGalleryState extends State<ProfileHeaderGallery> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = _primaryFirst(widget.images);
    if (images.isEmpty) {
      return const _EmptyState();
    }
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return AspectRatio(
      // A portrait crop remains dominant in portrait. In landscape a wide hero
      // prevents an 800 px-wide phone from creating a 1000+ px-tall image that
      // pushes every profile detail several screens below the fold.
      aspectRatio: isLandscape ? 16 / 9 : 3 / 4,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: images.length,
            itemBuilder: (_, i) {
              final image = images[i];
              final blurred = _isBlurred(image);
              return GestureDetector(
                key: ValueKey<String>('profile-gallery-image-${image.id}'),
                // A blurred photo is not interactive on this surface.
                onTap: blurred ? null : () => _openFullscreen(context, image),
                child: RepaintBoundary(
                  child: LikeBlurredImage(
                    url: image.url,
                    blur: blurred,
                    blurredUrl: _blurredUrl(image),
                    blurredThumbnailUrl: _blurredThumbnailUrl(image),
                    size: null,
                    shape: BoxShape.rectangle,
                    borderRadius: BorderRadius.zero,
                    alignment: profilePhotoAlignment,
                    blurSigma: 24,
                  ),
                ),
              );
            },
          ),
          if (images.length > 1) ...[
            PositionedDirectional(
              top: QeranSpacing.s12,
              end: QeranSpacing.s12,
              child: _IndexBadge(index: _index + 1, total: images.length),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: _DotsIndicator(count: images.length, current: _index),
            ),
          ],
        ],
      ),
    );
  }

  List<ProfileImage> _primaryFirst(List<ProfileImage> images) {
    final primaryIndex = images.indexWhere((image) => image.isProfile);
    if (primaryIndex <= 0) return images;
    return <ProfileImage>[
      images[primaryIndex],
      ...images.take(primaryIndex),
      ...images.skip(primaryIndex + 1),
    ];
  }

  /// Only ever reached for a clear photo, so the viewer needs no blur state.
  void _openFullscreen(BuildContext context, ProfileImage image) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, _, _) => _FullscreenViewer(image: image),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  bool _isBlurred(ProfileImage image) {
    if (widget.forceBlur) return true;
    return switch (image) {
      OwnerImage() => false,
      OtherProfileImage(:final isBlurred) => isBlurred,
    };
  }

  String? _blurredUrl(ProfileImage image) => switch (image) {
    OwnerImage() => null,
    OtherProfileImage(:final blurredUrl) => blurredUrl,
  };

  String? _blurredThumbnailUrl(ProfileImage image) => switch (image) {
    OwnerImage() => null,
    OtherProfileImage(:final blurredThumbnailUrl) => blurredThumbnailUrl,
  };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    return AspectRatio(
      aspectRatio: isLandscape ? 16 / 9 : 3 / 4,
      child: Container(
        color: QeranColors.creamSurface,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_rounded, size: 80, color: QeranColors.wine),
            QeranSpacing.vs8,
            Text(
              LocaleKeys.profile_no_photo.t(context),
              style: QeranTypography.caption.copyWith(
                color: QeranColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndexBadge extends StatelessWidget {
  final int index;
  final int total;
  const _IndexBadge({required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const BoxDecoration(
        color: QeranColors.overlayTintDark,
        borderRadius: QeranRadii.pill,
      ),
      child: Text(
        '$index / $total',
        style: QeranTypography.caption.copyWith(color: QeranColors.paper),
      ),
    );
  }
}

/// Bottom-centered page-position indicator. Gold + 8 dp for the active
/// dot, cream-surface + 6 dp for the rest. Animates between states so a
/// page swipe reads as a smooth shift rather than a hard cut.
class _DotsIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _DotsIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? QeranColors.gold : QeranColors.creamSurface,
          ),
        );
      }),
    );
  }
}

/// Fullscreen image viewer with pinch-zoom and pan. Uses a transparent
/// route with a black-overlay barrier so the user perceives it as a
/// modal lifted off the profile screen. Close button sits at the
/// top-trailing corner per platform convention.
class _FullscreenViewer extends StatelessWidget {
  final ProfileImage image;
  const _FullscreenViewer({required this.image});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 4.0,
                child: LikeBlurredImage(
                  url: image.url,
                  blur: false,
                  size: null,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.zero,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            PositionedDirectional(
              top: 16,
              end: 16,
              child: _FullscreenCloseButton(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenCloseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: QeranColors.paper,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).maybePop(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(Icons.close_rounded, color: QeranColors.wine, size: 22),
        ),
      ),
    );
  }
}
