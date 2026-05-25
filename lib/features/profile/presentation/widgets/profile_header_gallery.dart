import 'package:flutter/material.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/theme/app_text_style.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/features/likes/presentation/widgets/like_blurred_image.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/profile_image.dart';

/// Image hero for the Full Profile Details screen. Horizontal
/// `PageView` over the full gallery (or a single primary photo), with
/// a numerical 1/N indicator. Each cell uses [LikeBlurredImage] so
/// Bearer auth + conditional blur stay consistent with Likes / Matches.
///
/// Accepts the sealed [ProfileImage] type so both [OwnerImage] (gallery
/// with isApproved) and [OtherProfileImage] (with isBlurred) feed the
/// same widget. Owner images are always rendered unblurred.
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
              top: AppDimens.p12,
              right: AppDimens.p12,
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
      color: AppColors.primary.withValues(alpha: 0.06),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_rounded,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppDimens.p8),
          Text(
            LocaleKeys.profile_no_photo.t(context),
            style: AppTextStyles.caption
                .copyWith(color: AppColors.textSecondary),
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
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$index / $total',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
