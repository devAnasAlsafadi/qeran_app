import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/features/likes/presentation/widgets/like_blurred_image.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/profile_image.dart';

/// Image hero for the Full Profile Details screen. Horizontal
/// `PageView` over the full gallery (or a single primary photo), with
/// a numerical 1/N indicator.
class ProfileHeaderGallery extends StatefulWidget {
  final List<ProfileImage> images;
  final double height;

  const ProfileHeaderGallery({
    super.key,
    required this.images,
    this.height = 360,
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
    if (widget.images.isEmpty) {
      return _Placeholder(height: widget.height);
    }
    return SizedBox(
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.images.length,
            itemBuilder: (_, i) => RepaintBoundary(
              child: LikeBlurredImage(
                url: widget.images[i].url,
                blur: _isBlurred(widget.images[i]),
                size: null,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              top: QeranSpacing.s12,
              right: QeranSpacing.s12,
              child: _IndexBadge(
                index: _index + 1,
                total: widget.images.length,
              ),
            ),
        ],
      ),
    );
  }

  bool _isBlurred(ProfileImage image) {
    return switch (image) {
      OwnerImage() => false,
      OtherProfileImage(:final isBlurred) => isBlurred,
    };
  }
}

class _Placeholder extends StatelessWidget {
  final double height;
  const _Placeholder({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: QeranColors.creamSurface,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_rounded,
            size: 64,
            color: QeranColors.wine40,
          ),
          QeranSpacing.vs8,
          Text(
            LocaleKeys.profile_no_photo.t(context),
            style: QeranTypography.caption,
          ),
        ],
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
