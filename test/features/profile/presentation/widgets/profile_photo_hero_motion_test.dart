import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/routes/app_router.dart';
import 'package:qeran/core/routes/route_name.dart';
import 'package:qeran/features/likes/presentation/widgets/like_blurred_image.dart';
import 'package:qeran/features/profile/domain/entities/other_profile.dart';
import 'package:qeran/features/profile/domain/entities/profile_entry_source.dart';
import 'package:qeran/features/profile/domain/entities/profile_image.dart';
import 'package:qeran/features/profile/presentation/full_profile_details_args.dart';
import 'package:qeran/features/profile/presentation/widgets/full_profile_image_hero.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_header_gallery.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_photo_hero_motion.dart';

void main() {
  const secondary = OtherProfileImage(
    id: 'secondary',
    url: 'https://example.com/secondary.jpg',
    isProfile: false,
    isBlurred: false,
  );
  const primary = OtherProfileImage(
    id: 'primary',
    url: 'https://example.com/primary.jpg',
    isProfile: true,
    isBlurred: false,
  );

  test('shared hero tag and rect tween keep stable endpoints', () {
    expect(profilePhotoHeroTag('user-1'), 'profile_hero_user-1');

    final tween = profilePhotoHeroRectTween(
      const Rect.fromLTWH(20, 100, 200, 280),
      const Rect.fromLTWH(0, 24, 400, 520),
    );
    expect(tween.lerp(0), tween.begin);
    expect(tween.lerp(1), tween.end);
  });

  testWidgets('gallery opens on the profile image with the shared crop', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: ProfileHeaderGallery(images: [secondary, primary]),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final renderedImages = tester
        .widgetList<LikeBlurredImage>(find.byType(LikeBlurredImage))
        .toList(growable: false);
    expect(renderedImages.first.url, primary.url);
    expect(renderedImages.first.alignment, profilePhotoAlignment);
    expect(renderedImages.first.blurSigma, 24);
  });

  testWidgets('full profile exposes the shared photo flight configuration', (
    tester,
  ) async {
    const profile = OtherProfile(
      id: 'user-1',
      name: 'User',
      age: null,
      matchingScore: 0,
      images: [primary],
      placements: [],
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: FullProfileImageHero(profile: profile),
            ),
          ),
        ),
      ),
    );

    final hero = tester.widget<Hero>(find.byType(Hero));
    expect(hero.tag, profilePhotoHeroTag(profile.id));
    expect(hero.createRectTween, same(profilePhotoHeroRectTween));
    expect(hero.flightShuttleBuilder, same(profilePhotoFlightShuttle));
  });

  testWidgets('shared photo flight runs safely in both directions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: GestureDetector(
                key: const ValueKey<String>('open-profile'),
                onTap: () => Navigator.of(context).push(
                  PageRouteBuilder<void>(
                    transitionDuration: const Duration(milliseconds: 340),
                    reverseTransitionDuration: const Duration(
                      milliseconds: 260,
                    ),
                    pageBuilder: (_, _, _) => const _HeroDestination(),
                  ),
                ),
                child: Hero(
                  tag: profilePhotoHeroTag('flight-user'),
                  createRectTween: profilePhotoHeroRectTween,
                  flightShuttleBuilder: profilePhotoFlightShuttle,
                  child: const SizedBox(
                    width: 160,
                    height: 220,
                    child: ColoredBox(color: Colors.deepPurple),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey<String>('open-profile')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 170));
    expect(tester.takeException(), isNull);
    expect(find.byType(ClipRRect), findsOneWidget);
    await tester.pumpAndSettle();

    Navigator.of(tester.element(find.byType(_HeroDestination))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 130));
    expect(tester.takeException(), isNull);
    expect(find.byType(ClipRRect), findsOneWidget);
    await tester.pumpAndSettle();
  });

  test('full-profile route uses the dedicated shared-photo timing', () {
    const profile = OtherProfile(
      id: 'user-1',
      name: 'User',
      age: null,
      matchingScore: 0,
      images: [primary],
      placements: [],
    );
    final route =
        AppRouter().onGenerateRoute(
              const RouteSettings(
                name: RouteNames.fullProfileDetails,
                arguments: FullProfileDetailsArgs(
                  userId: 'user-1',
                  entry: ProfileEntrySource.discovery,
                  initialData: profile,
                ),
              ),
            )
            as TransitionRoute<dynamic>;

    expect(route.transitionDuration, const Duration(milliseconds: 340));
    expect(route.reverseTransitionDuration, const Duration(milliseconds: 260));
  });
}

class _HeroDestination extends StatelessWidget {
  const _HeroDestination();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: Hero(
          tag: profilePhotoHeroTag('flight-user'),
          createRectTween: profilePhotoHeroRectTween,
          flightShuttleBuilder: profilePhotoFlightShuttle,
          child: const SizedBox(
            width: 400,
            height: 520,
            child: ColoredBox(color: Colors.deepPurple),
          ),
        ),
      ),
    );
  }
}
