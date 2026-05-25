import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';

/// Renders the candidate's photo with a heavy blur, a 30 % black overlay,
/// and the one-and-only design-system-approved bottom gradient.
///
/// Attaches the session's Bearer token to the image request via
/// `httpHeaders`. If the cubit isn't in scope (widget tests) or the user
/// isn't authenticated, the request fires anonymously and the server's
/// 401 produces an error widget — never a crash.
class DiscoveryBlurredImage extends StatelessWidget {
  final String url;

  /// Visible only to the test layer, where the blur sigma matters
  /// (some test environments choke on `ImageFilter.blur`). Production
  /// always uses 24.0.
  final double sigma;

  const DiscoveryBlurredImage({
    super.key,
    required this.url,
    this.sigma = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final headers = _authHeaders(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: CachedNetworkImage(
            imageUrl: url,
            httpHeaders: headers,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: AppColors.surface),
            errorWidget: (_, _, _) =>
                Container(color: AppColors.surface),
          ),
        ),
        Container(color: AppColors.black.withValues(alpha: 0.30)),
        const Align(
          alignment: Alignment.bottomCenter,
          child: _BottomGradient(),
        ),
      ],
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
      // anonymous request.
    }
    return null;
  }
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
              AppColors.black.withValues(alpha: 0),
              AppColors.black.withValues(alpha: 0.55),
            ],
          ),
        ),
      ),
    );
  }
}
