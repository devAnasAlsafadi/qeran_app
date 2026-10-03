import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/api/end_points.dart';
import '../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../core/design_system/tokens/qeran_spacing.dart';
import '../../../../core/design_system/tokens/qeran_typography.dart';
import '../../../../core/design_system/widgets/qeran_button.dart';
import '../../../../core/extensions/localization_extension.dart';
import '../../../../generated/locale_keys.g.dart';
import '../../../auth/presentation/session_image_headers.dart';

/// An image in Community: a post's photo, a matchmaker's avatar, a video's
/// poster. [url] may be relative — a post image or an avatar, on our server,
/// loaded with the session's token — or absolute: a signed video poster or
/// the dev mock's media, which get no token ([sessionImageHeaders] sends it
/// to our own server only). Images are immutable on the server, so the device
/// caches them.
///
/// While it loads: [placeholder], cream by default. If it fails: [fallback]
/// when given (an avatar falls back to its monogram), otherwise «تعذّر تحميل
/// الصورة» with a retry that fetches it again (A8).
class CommunityNetworkImage extends StatefulWidget {
  const CommunityNetworkImage(
    this.url, {
    super.key,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.fallback,
  });

  final String url;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? fallback;

  @override
  State<CommunityNetworkImage> createState() => _CommunityNetworkImageState();
}

class _CommunityNetworkImageState extends State<CommunityNetworkImage> {
  /// Bumped by a retry: a new key is a new request. The package has already
  /// dropped a failed image from the cache.
  int _attempt = 0;

  void _retry() => setState(() => _attempt++);

  Widget _failed() => widget.fallback ?? CommunityImageFailed(onRetry: _retry);

  @override
  Widget build(BuildContext context) {
    if (widget.url.trim().isEmpty) return _failed();
    final url = EndPoints.absoluteUrl(widget.url);
    return CachedNetworkImage(
      key: ValueKey(_attempt),
      imageUrl: url,
      httpHeaders: sessionImageHeaders(context, url),
      fit: widget.fit,
      fadeInDuration: Duration.zero,
      placeholder: (_, _) =>
          widget.placeholder ??
          const ColoredBox(color: QeranColors.creamSurface),
      errorWidget: (_, _, _) => _failed(),
    );
  }
}

/// A8: the image couldn't load — say so, and offer to try again. Cream, with
/// the message scaled down rather than overflowing a small frame.
class CommunityImageFailed extends StatelessWidget {
  const CommunityImageFailed({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: QeranColors.creamSurface,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.broken_image_rounded,
                size: 30,
                color: QeranColors.inkMuted,
              ),
              const SizedBox(height: QeranSpacing.s6),
              Text(
                LocaleKeys.community_image_failed.t(context),
                style: QeranTypography.bodySm.copyWith(
                  color: QeranColors.inkMuted,
                ),
              ),
              QeranButton(
                label: LocaleKeys.community_retry.t(context),
                onPressed: onRetry,
                variant: QeranButtonVariant.ghost,
                size: QeranButtonSize.compact,
                leadingIcon: Icons.refresh_rounded,
                fullWidth: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
