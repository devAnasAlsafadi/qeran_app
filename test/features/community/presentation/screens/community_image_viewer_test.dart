import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_page_indicator.dart';
import 'package:qeran/features/community/domain/entities/community_media.dart';
import 'package:qeran/features/community/presentation/screens/community_image_viewer.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/community_post_card.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/post_image_set.dart';
import 'package:qeran/features/community/presentation/widgets/viewer/viewer_top_bar.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../auth/presentation/fake_session.dart';
import '../../fixtures/community_post_fixtures.dart';

/// A post's photos full screen (G1–G3): from the one tapped, swipe, zoom,
/// swipe down to close.
void main() {
  setUpAll(initShippedStrings);

  const images = [
    CommunityImage(url: 'https://cdn.example/1.jpg', width: 1080, height: 1080),
    CommunityImage(url: 'https://cdn.example/2.jpg', width: 1080, height: 1350),
    CommunityImage(url: 'https://cdn.example/3.jpg', width: 1920, height: 1080),
  ];

  Future<void> openFromCard(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    List<CommunityImage> photos = images,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await pumpShippedStrings(
      tester,
      locale,
      child: withSession(
        SingleChildScrollView(
          child: CommunityPostCard(
            post: testPost(media: CommunityImageSet(photos)),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(PostImageSet));
    await tester.pumpAndSettle();
  }

  Finder counter(String text) =>
      find.descendant(of: find.byType(ViewerTopBar), matching: find.text(text));

  testWidgets('G1: opened at the tapped photo, the counter and the dots', (
    tester,
  ) async {
    await openFromCard(tester);

    expect(find.byType(CommunityImageViewer), findsOneWidget);
    expect(counter('1 / 3'), findsOneWidget);
    final dots = tester.widget<QeranPageDots>(find.byType(QeranPageDots).last);
    expect(dots.tone, QeranPageDotsTone.wine);
    expect(dots.current, 0);

    await tester.drag(find.byType(CommunityImageViewer), const Offset(-300, 0));
    await tester.pumpAndSettle();
    expect(counter('2 / 3'), findsOneWidget);
  });

  testWidgets('G2: a double tap zooms — no dots, the pages hold still; '
      'again, back', (tester) async {
    await openFromCard(tester);
    final photo = find.byType(InteractiveViewer).first;

    await tester.tap(photo);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(photo);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(CommunityImageViewer),
        matching: find.byType(QeranPageDots),
      ),
      findsNothing,
    );
    final pages = tester.widget<PageView>(
      find.descendant(
        of: find.byType(CommunityImageViewer),
        matching: find.byType(PageView),
      ),
    );
    expect(pages.physics, isA<NeverScrollableScrollPhysics>());

    await tester.tap(photo);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(photo);
    await tester.pumpAndSettle();
    expect(find.byType(QeranPageDots), findsWidgets);
  });

  testWidgets('swipe down closes it; a small pull springs back', (
    tester,
  ) async {
    await openFromCard(tester);

    await tester.drag(find.byType(CommunityImageViewer), const Offset(0, 60));
    await tester.pumpAndSettle();
    expect(find.byType(CommunityImageViewer), findsOneWidget);

    await tester.drag(find.byType(CommunityImageViewer), const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(find.byType(CommunityImageViewer), findsNothing);
  });

  testWidgets("G3: a photo that won't load — on wine, with its retry [ar]", (
    tester,
  ) async {
    await openFromCard(
      tester,
      locale: const Locale('ar'),
      photos: const [CommunityImage(url: '', width: 1080, height: 1080)],
    );

    final viewer = find.byType(CommunityImageViewer);
    expect(
      find.descendant(of: viewer, matching: find.text('تعذّر تحميل الصورة')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: viewer, matching: find.text('حاول مرة أخرى')),
      findsOneWidget,
    );
  });

  testWidgets('one photo: no counter, no dots; close at the start [ar]', (
    tester,
  ) async {
    await openFromCard(
      tester,
      locale: const Locale('ar'),
      photos: [images.first],
    );

    expect(find.textContaining(' / '), findsNothing);
    expect(
      find.descendant(
        of: find.byType(CommunityImageViewer),
        matching: find.byType(QeranPageDots),
      ),
      findsNothing,
    );
    final close = tester.getCenter(find.byIcon(Icons.close_rounded));
    expect(close.dx, greaterThan(390 / 2));

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(CommunityImageViewer), findsNothing);
  });
}
