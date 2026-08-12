import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';

/// Renders the candidate's actual photo with a privacy-preserving soft blur,
/// and the one-and-only design-system-approved bottom gradient.
///
/// Attaches the session's Bearer token to the image request via
/// `httpHeaders`. If the cubit isn't in scope (widget tests) or the user
/// isn't authenticated, the request fires anonymously and the server's
/// 401 produces an error widget — never a crash.
class DiscoveryBlurredImage extends StatelessWidget {
  final String url;
  final Alignment alignment;

  /// Visible only to the test layer, where the blur sigma matters
  /// (some test environments choke on `ImageFilter.blur`). Production
  /// always uses 12.0.
  final double sigma;

  const DiscoveryBlurredImage({
    super.key,
    required this.url,
    this.sigma = 12.0,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final headers = _discoveryImageAuthHeaders(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
            child: CachedNetworkImage(
              imageUrl: url,
              httpHeaders: headers,
              fit: BoxFit.cover,
              alignment: alignment,
              filterQuality: FilterQuality.low,
              memCacheWidth: 600,
              maxWidthDiskCache: 600,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              placeholder: (_, _) => Container(color: QeranColors.creamSurface),
              errorWidget: (_, _, _) =>
                  Container(color: QeranColors.creamSurface),
            ),
          ),
        ),
        Container(color: QeranColors.wine.withValues(alpha: 0.18)),
        const Align(
          alignment: Alignment.bottomCenter,
          child: _BottomGradient(),
        ),
      ],
    );
  }
}

/// Warms the next profile photo in the file + decoded image caches without
/// placing another blurred image in the render tree.
Future<void> precacheDiscoveryPhoto(BuildContext context, String url) {
  if (url.isEmpty) return Future<void>.value();
  final provider = ResizeImage.resizeIfNeeded(
    600,
    null,
    CachedNetworkImageProvider(
      url,
      headers: _discoveryImageAuthHeaders(context),
    ),
  );
  return precacheImage(provider, context, onError: (_, _) {});
}

Map<String, String>? _discoveryImageAuthHeaders(BuildContext context) {
  try {
    final state = context.read<UserSessionCubit>().state;
    if (state is UserSessionAuthenticated) {
      final token = state.user.token;
      if (token != null && token.isNotEmpty) {
        return {'Authorization': 'Bearer $token'};
      }
    }
  } catch (_) {
    // No cubit in scope — happens in widget tests. Fall through to anonymous.
  }
  return null;
}

class _BottomGradient extends StatelessWidget {
  const _BottomGradient();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.45,
      widthFactor: 1.0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              QeranColors.wine.withValues(alpha: 0),
              QeranColors.wine.withValues(alpha: 0.45),
            ],
          ),
        ),
      ),
    );
  }
}
