import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../../fixtures/community_post_fixtures.dart';
import 'post_card_rig.dart';

Color? _iconColor(WidgetTester tester, IconData icon) =>
    tester.widget<Icon>(find.byIcon(icon)).color;

void main() {
  setUpAll(initShippedStrings);

  for (final MapEntry(key: locale, value: copy) in cardLocales.entries) {
    final lang = locale.languageCode;

    testWidgets('A1 liked, 128 / 14 [$lang]', (tester) async {
      await pumpCard(
        tester,
        testPost(likeCount: 128, likedByMe: true, commentCount: 14),
        locale: locale,
      );

      expect(_iconColor(tester, Icons.favorite_rounded), QeranColors.goldDeep);
      expect(find.text('128'), findsOneWidget);
      expect(find.text(copy.discussion), findsOneWidget);
      expect(find.text('14'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    });

    testWidgets('A15 nothing yet: Like, and «Discuss ›» [$lang]', (
      tester,
    ) async {
      await pumpCard(tester, testPost(), locale: locale);

      expect(
        _iconColor(tester, Icons.favorite_border_rounded),
        QeranColors.inkBody,
      );
      expect(find.text(copy.like), findsOneWidget);
      expect(find.text(copy.discuss), findsOneWidget);
      expect(find.text('·'), findsNothing);
    });

    testWidgets('A17 thousands [$lang]', (tester) async {
      await pumpCard(
        tester,
        testPost(likeCount: 1240, commentCount: 1500),
        locale: locale,
      );

      expect(find.text(copy.likes1240), findsOneWidget);
      expect(find.text(copy.comments1500), findsOneWidget);
    });

    testWidgets('the header: name, chip, how long ago [$lang]', (tester) async {
      final twoHoursAgo = DateTime.now().toUtc().subtract(
        const Duration(hours: 2),
      );
      await pumpCard(tester, testPost(createdAt: twoHoursAgo), locale: locale);

      expect(find.text(huda.displayName), findsOneWidget);
      expect(find.text(copy.matchmaker), findsOneWidget);
      expect(find.text(copy.twoHoursAgo), findsOneWidget);
    });

    testWidgets('A20 read-only: Like at 40 %, still answering a tap '
        '[$lang]', (tester) async {
      var likes = 0;
      await pumpCard(
        tester,
        testPost(),
        locale: locale,
        readOnly: true,
        onLike: () => likes++,
      );

      final dimmer = tester.widget<Opacity>(
        find.ancestor(
          of: find.byIcon(Icons.favorite_border_rounded),
          matching: find.byType(Opacity),
        ),
      );
      expect(dimmer.opacity, 0.4);
      await tester.tap(find.text(copy.like));
      expect(likes, 1);
    });
  }

  testWidgets('no time from the server: no time line', (tester) async {
    await pumpCard(tester, testPost());

    expect(find.textContaining('ago'), findsNothing);
  });

  testWidgets('S16: a screen reader hears the action and the count', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpCard(
      tester,
      testPost(likeCount: 128, likedByMe: true, commentCount: 14),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Like')),
      isSemantics(label: 'Like', value: '128', isButton: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Discussion')),
      isSemantics(label: 'Discussion', value: '14', isButton: true),
    );
    semantics.dispose();
  });
}
