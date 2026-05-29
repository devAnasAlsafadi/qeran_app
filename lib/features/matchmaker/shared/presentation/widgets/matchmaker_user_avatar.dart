import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design_system/tokens/qeran_colors.dart';
import '../../../../auth/presentation/blocs/user_session/user_session_cubit.dart';
import '../../../../auth/presentation/blocs/user_session/user_session_state.dart';

/// The ONLY entry point for rendering a profile image inside the
/// Matchmaker module. JWT-headered, never blurred — backend sends
/// `isBlurred=false` for the moderator role, and we don't even read
/// the flag here so a server bug can never blur a moderator's view.
///
/// Pass an already-absolute URL (the data layer should run it through
/// `EndPoints.absoluteUrl` before reaching the UI).
class MatchmakerUserAvatar extends StatelessWidget {
  const MatchmakerUserAvatar({
    super.key,
    required this.url,
    this.size,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.fallbackIcon = Icons.person_rounded,
    this.fit = BoxFit.cover,
    this.alignment = const Alignment(0, -0.3),
  });

  final String? url;
  final double? size;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;
  final BoxFit fit;
  final Alignment alignment;

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
    return CachedNetworkImage(
      imageUrl: u,
      httpHeaders: _authHeaders(context),
      fit: fit,
      alignment: alignment,
      placeholder: (_, _) => _placeholder(),
      errorWidget: (_, _, _) => _fallback(),
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
      // No cubit in scope (widget tests). Anonymous request → fallback
      // surfaces if the server returns 401.
    }
    return null;
  }

  Widget _placeholder() {
    return const ColoredBox(color: QeranColors.creamSurface);
  }

  Widget _fallback() {
    final iconSize = (size == null) ? 36.0 : size! * 0.55;
    return ColoredBox(
      color: QeranColors.creamSurface,
      child: Center(
        child: Icon(fallbackIcon, size: iconSize, color: QeranColors.inkMuted),
      ),
    );
  }
}
