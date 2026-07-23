import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';

/// Shared crop used by the discovery card and the full-profile gallery.
///
/// A small upward bias keeps faces stable while the shared photo grows.
const Alignment profilePhotoAlignment = Alignment(0, -0.3);

String profilePhotoHeroTag(String profileId) => 'profile_hero_$profileId';

RectTween profilePhotoHeroRectTween(Rect? begin, Rect? end) {
  return ProfilePhotoHeroRectTween(begin: begin, end: end);
}

/// Keeps the exact source photo alive for the whole flight. This avoids
/// decoding and cross-fading two blurred full-screen images on the raster
/// thread while the card is expanding.
Widget profilePhotoFlightShuttle(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection direction,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  final fromHero = fromHeroContext.widget as Hero;
  Widget shuttle = AnimatedBuilder(
    animation: animation,
    child: RepaintBoundary(child: fromHero.child),
    builder: (context, child) {
      final rawProgress = direction == HeroFlightDirection.push
          ? animation.value
          : 1 - animation.value;
      final progress = Curves.easeInOutCubicEmphasized.transform(
        rawProgress.clamp(0.0, 1.0),
      );
      final radius = direction == HeroFlightDirection.push
          ? QeranRadii.panel * (1 - progress)
          : QeranRadii.panel * progress;
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
    },
  );

  // Hero flights live in Navigator's overlay, outside feature-level inherited
  // widgets. Preserve the authenticated image request while flying in either
  // direction; tests and anonymous flows safely fall through.
  try {
    shuttle = BlocProvider<UserSessionCubit>.value(
      value: fromHeroContext.read<UserSessionCubit>(),
      child: shuttle,
    );
  } catch (_) {
    // No session cubit in scope.
  }
  return InheritedTheme.captureAll(fromHeroContext, shuttle);
}

class ProfilePhotoHeroRectTween extends RectTween {
  ProfilePhotoHeroRectTween({super.begin, super.end});

  @override
  Rect? lerp(double t) {
    if (begin == null || end == null) return null;
    final curvedT = Curves.easeInOutCubicEmphasized.transform(t);
    return Rect.fromLTRB(
      begin!.left + (end!.left - begin!.left) * curvedT,
      begin!.top + (end!.top - begin!.top) * curvedT,
      begin!.right + (end!.right - begin!.right) * curvedT,
      begin!.bottom + (end!.bottom - begin!.bottom) * curvedT,
    );
  }
}
