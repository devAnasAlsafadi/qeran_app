import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/presentation/widgets/like_blurred_image.dart';
import 'package:qeran/features/likes/presentation/widgets/photo_view_access_host.dart';
import 'package:qeran/features/likes/presentation/blocs/photo_view_state.dart';

/// The server now renders the blurred variants, so the client filter becomes a
/// fallback. The load-bearing property is WHICH url gets requested: the
/// original must never be fetched while the one-time view policy is closed,
/// but the redacted rendition always may.
void main() {
  const original = 'https://cdn.test/original.jpg';
  const blurred = 'https://cdn.test/blurred.jpg';
  const blurredThumb = 'https://cdn.test/blurred-thumb.jpg';

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(home: Scaffold(body: SizedBox(width: 120, height: 120, child: child))),
  );

  List<String> requestedUrls(WidgetTester tester) => tester
      .widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage))
      .map((w) => w.imageUrl)
      .toList();

  testWidgets('a blurred image requests the server rendition, not the original',
      (tester) async {
    await pump(
      tester,
      const LikeBlurredImage(
        url: original,
        blur: true,
        blurredUrl: blurred,
        size: null,
      ),
    );

    expect(requestedUrls(tester), [blurred]);
    expect(
      find.byType(ImageFiltered),
      findsNothing,
      reason: 'the server already destroyed the detail — no client filter',
    );
  });

  testWidgets('compact surfaces prefer the thumbnail rendition',
      (tester) async {
    await pump(
      tester,
      const LikeBlurredImage(
        url: original,
        blur: true,
        blurredUrl: blurred,
        blurredThumbnailUrl: blurredThumb,
        preferThumbnail: true,
        size: null,
      ),
    );

    expect(requestedUrls(tester), [blurredThumb]);
  });

  testWidgets('either rendition serves either size rather than dropping out',
      (tester) async {
    // Both are already destroyed detail, so a missing thumbnail is no reason
    // to fall back to filtering the original.
    await pump(
      tester,
      const LikeBlurredImage(
        url: original,
        blur: true,
        blurredUrl: blurred,
        preferThumbnail: true,
        size: null,
      ),
    );

    expect(requestedUrls(tester), [blurred]);
  });

  testWidgets('no rendition falls back to the client filter', (tester) async {
    await pump(
      tester,
      const LikeBlurredImage(url: original, blur: true, size: null),
    );

    expect(requestedUrls(tester), [original]);
    expect(find.byType(ImageFiltered), findsOneWidget);
  });

  testWidgets('an unblurred image still requests the original', (tester) async {
    await pump(
      tester,
      const LikeBlurredImage(
        url: original,
        blur: false,
        blurredUrl: blurred,
        size: null,
      ),
    );

    expect(requestedUrls(tester), [original]);
  });

  group('under a closed one-time view policy', () {
    Widget scoped(Widget child) => PhotoViewScope(
      // `available` means the reveal has not been spent: the original is off
      // limits.
      state: const PhotoViewState(phase: PhotoViewPhase.available),
      onReveal: () {},
      onRetry: () {},
      onImageForbidden: () {},
      child: child,
    );

    testWidgets('the server rendition is shown, not a lock glyph',
        (tester) async {
      await pump(
        tester,
        scoped(
          const LikeBlurredImage(
            url: original,
            blur: true,
            blurredUrl: blurred,
            blockImageBytes: true,
            size: null,
          ),
        ),
      );

      expect(requestedUrls(tester), [blurred]);
    });

    testWidgets('the original is never requested even when asked for clear',
        (tester) async {
      // The scope overrides the caller: a widget that thinks the photo is
      // clear must still not fetch it while the window is shut.
      await pump(
        tester,
        scoped(
          const LikeBlurredImage(
            url: original,
            blur: false,
            blurredUrl: blurred,
            size: null,
          ),
        ),
      );

      expect(requestedUrls(tester), isNot(contains(original)));
      expect(requestedUrls(tester), [blurred]);
    });

    testWidgets('without a rendition it still refuses to fetch anything',
        (tester) async {
      await pump(
        tester,
        scoped(
          const LikeBlurredImage(
            url: original,
            blur: true,
            blockImageBytes: true,
            size: null,
          ),
        ),
      );

      expect(requestedUrls(tester), isEmpty);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });
  });
}
