import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_page_indicator.dart';
import 'package:qeran/features/community/domain/entities/community_media.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/post_image_set.dart';

import '../../../fixtures/community_post_fixtures.dart';

/// [images] at the card's width (358), in a UI of [direction].
Future<void> _pump(
  WidgetTester tester,
  List<CommunityImage> images, {
  TextDirection direction = TextDirection.ltr,
  ValueChanged<int>? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    builder: (_, child) =>
        Directionality(textDirection: direction, child: child!),
    home: Center(
      child: SizedBox(
        width: 358,
        child: PostImageSet(images: images, onTap: onTap),
      ),
    ),
  ),
);

List<CommunityImage> _set(int n) => [
  for (var i = 0; i < n; i++) testImage(url: '/api/community/media/m-$i'),
];

double _aspect(WidgetTester tester) =>
    tester.widget<AspectRatio>(find.byType(AspectRatio)).aspectRatio;

QeranPageDots _dots(WidgetTester tester) =>
    tester.widget<QeranPageDots>(find.byType(QeranPageDots));

Future<void> _swipe(WidgetTester tester, double dx) async {
  await tester.drag(find.byType(PageView), Offset(dx, 0));
  await tester.pumpAndSettle();
}

void main() {
  group('one photo: its own frame, nothing else (A4)', () {
    const sizes = {(1080, 1350): 0.8, (900, 1600): 0.8, (1920, 1080): 16 / 9};
    for (final MapEntry(key: (w, h), value: ratio) in sizes.entries) {
      testWidgets('$w × $h → $ratio', (tester) async {
        await _pump(tester, [testImage(width: w, height: h)]);

        expect(_aspect(tester), closeTo(ratio, 1e-9));
        expect(find.byType(QeranPageCounter), findsNothing);
        expect(find.byType(QeranPageDots), findsNothing);
      });
    }
  });

  testWidgets('three: a square carousel, its count and paper dots (A5)', (
    tester,
  ) async {
    await _pump(tester, _set(3));

    expect(_aspect(tester), 1);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(_dots(tester).count, 3);
    expect(_dots(tester).current, 0);
    expect(_dots(tester).tone, QeranPageDotsTone.paper);
  });

  testWidgets('swiped to the second: «2 / 3», second dot (A6)', (tester) async {
    await _pump(tester, _set(3));

    await _swipe(tester, -300);

    expect(find.text('2 / 3'), findsOneWidget);
    expect(_dots(tester).current, 1);
  });

  testWidgets('right to left, the next photo comes from the left', (
    tester,
  ) async {
    await _pump(tester, _set(3), direction: TextDirection.rtl);

    await _swipe(tester, 300);

    expect(find.text('2 / 3'), findsOneWidget);
  });

  testWidgets('eight: six dots that follow the page (A7, S2)', (tester) async {
    await _pump(tester, _set(8));
    expect(_dots(tester).count, 6);

    for (var i = 0; i < 7; i++) {
      await _swipe(tester, -300);
    }

    expect(find.text('8 / 8'), findsOneWidget);
    expect((_dots(tester).count, _dots(tester).current), (6, 5));
  });

  testWidgets('a tap opens the viewer at that photo', (tester) async {
    int? opened;
    await _pump(tester, _set(3), onTap: (i) => opened = i);

    await _swipe(tester, -300);
    await tester.tap(find.byType(PageView));

    expect(opened, 1);
  });
}
