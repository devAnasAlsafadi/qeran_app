import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';

/// Shared rounded image with optional blur.
///
/// Used by both the Received-likes card and the Matches card / gallery
/// so the blur sigma and the **authenticated request** stay consistent
/// across screens.
///
/// Profile image URLs on `/api/users/profile-images/...` require the
/// Bearer token — without it the server returns 401 and we'd otherwise
/// render the gray fallback icon. We pull the token from
/// [UserSessionCubit] via `context.read`; if the cubit isn't in scope
/// (widget tests) the request fires anonymously and the error widget
/// shows the same gray fallback — never a crash.
///
/// When [size] is null, the widget fills its parent (use it inside a
/// `SizedBox` / `GridView` cell). When non-null, the widget is a square
/// of that side.
class LikeBlurredImage extends StatelessWidget {
  final String? url;
  final bool blur;
  final double? size;
  final IconData fallbackIcon;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  /// Image alignment passed to `CachedNetworkImage`. Defaults to centre.
  /// Portrait gallery callers should pass `Alignment(0, -0.3)` to bias
  /// the crop toward the top third where faces sit (matrimony-app rule
  /// of thumb).
  final Alignment alignment;

  /// Image fit passed to `CachedNetworkImage`. Defaults to `BoxFit.cover`
  /// (the existing behaviour at every legacy call site). Fullscreen
  /// viewers pass `BoxFit.contain` so the entire image is visible.
  final BoxFit fit;

  /// Allows large profile surfaces to match the stronger discovery blur
  /// during a shared-photo transition. Existing compact callers keep 6.
  final double blurSigma;

  const LikeBlurredImage({
    super.key,
    required this.url,
    required this.blur,
    this.size = 64,
    this.fallbackIcon = Icons.person_rounded,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.alignment = Alignment.center,
    this.fit = BoxFit.cover,
    this.blurSigma = _defaultSigma,
  });

  /// Soft blur — strong enough to obscure facial features without
  /// wiping the image into a uniform gray disc. The Figma reference
  /// shows a recognisable silhouette + colour mood; 6 sigma matches.
  static const double _defaultSigma = 6.0;

  @override
  Widget build(BuildContext context) {
    final image = _buildImageOrFallback(context);
    final clipped = shape == BoxShape.circle
        ? ClipOval(child: image)
        : ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(12),
            child: image,
          );
    if (size == null) return SizedBox.expand(child: clipped);
    return SizedBox(width: size, height: size, child: clipped);
  }

  Widget _buildImageOrFallback(BuildContext context) {
    final u = url;
    if (u == null || u.isEmpty) return _fallback();
    final img = CachedNetworkImage(
      imageUrl: u,
      httpHeaders: _authHeaders(context),
      fit: fit,
      alignment: alignment,
      placeholder: (_, _) => _placeholder(),
      errorWidget: (_, _, _) => _fallback(),
    );
    if (!blur) return img;
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
      child: img,
    );
  }

  Map<String, String>? _authHeaders(BuildContext context) {
    try {
      final state = context.read<UserSessionCubit>().state;
      if (state is UserSessionAuthenticated) {
        final token = state.user.token;
        if (token != null && token.isNotEmpty) {
          return {'Authorization': 'Bearer $token'};
        }
      }
    } catch (_) {
      // No cubit in scope — happens in widget tests. Fall through to
      // anonymous request; the errorWidget surfaces the gray fallback.
    }
    return null;
  }

  Widget _placeholder() {
    return ColoredBox(color: QeranColors.wine.withValues(alpha: 0.06));
  }

  Widget _fallback() {
    final iconSize = (size == null) ? 36.0 : size! * 0.55;
    return Container(
      color: QeranColors.wine.withValues(alpha: 0.06),
      alignment: Alignment.center,
      child: Icon(fallbackIcon, size: iconSize, color: QeranColors.inkFaint),
    );
  }
}
