import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_monogram.dart';
import 'package:qeran/features/community/domain/entities/community_comment.dart';
import 'package:qeran/features/community/presentation/widgets/comments/comment_row.dart';
import 'package:qeran/features/community/presentation/widgets/community_network_image.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../../fixtures/community_comment_fixtures.dart';
import '../../../fixtures/community_post_fixtures.dart';

/// [comment]'s row in a phone-wide column, in [locale]'s UI.
Future<void> _pump(
  WidgetTester tester,
  CommunityComment comment, {
  Locale locale = const Locale('en'),
  bool readOnly = false,
  VoidCallback? onLike,
  double width = 390,
}) => pumpShippedStrings(
  tester,
  locale,
  child: Center(
    child: SizedBox(
      width: width,
      child: CommentRow(comment: comment, readOnly: readOnly, onLike: onLike),
    ),
  ),
);

final _anHourAgo = DateTime.now().toUtc().subtract(const Duration(hours: 1));

void main() {
  setUpAll(initShippedStrings);

  group('who and when, in each UI (Q6: rows short in English, long in '
      'Arabic)', () {
    testWidgets('en', (tester) async {
      await _pump(tester, testComment(createdAt: _anHourAgo));

      expect(find.text(sara.displayName), findsOneWidget);
      expect(find.text('· 1h'), findsOneWidget);
    });

    testWidgets('ar', (tester) async {
      await _pump(
        tester,
        testComment(createdAt: _anHourAgo),
        locale: const Locale('ar'),
      );

      expect(find.text('· منذ ساعة'), findsOneWidget);
    });

    testWidgets('no time from the server: none shown', (tester) async {
      await _pump(tester, testComment());

      expect(find.textContaining('·'), findsNothing);
    });
  });

  testWidgets('a member: the plain monogram, no chip (D10)', (tester) async {
    await _pump(tester, testComment());

    final monogram = tester.widget<QeranMonogram>(find.byType(QeranMonogram));
    expect(monogram.tone, QeranMonogramTone.plain);
    expect(find.text('Matchmaker'), findsNothing);
  });

  group('a matchmaker\'s reply (I2)', () {
    testWidgets('her ring and the chip', (tester) async {
      await _pump(tester, testReply());

      final monogram = tester.widget<QeranMonogram>(find.byType(QeranMonogram));
      expect(monogram.tone, isNot(QeranMonogramTone.plain));
      expect(find.text('Matchmaker'), findsOneWidget);
    });

    testWidgets('her photo inside it', (tester) async {
      await _pump(tester, testReply(author: nouraWithPhoto));

      expect(find.byType(CommunityNetworkImage), findsOneWidget);
    });

    testWidgets('a long kunya on a small phone: cut at its own end, the '
        'chip whole', (tester) async {
      await _pump(tester, testReply(author: ummAbdulrahman), width: 320);

      expect(tester.takeException(), isNull);
      expect(find.text('Matchmaker'), findsOneWidget);
    });
  });

  testWidgets('the text in its own direction and script (D13)', (tester) async {
    await _pump(
      tester,
      testComment(author: fahad, text: fahadText),
      locale: const Locale('ar'),
    );

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text(fahadText),
    );
    expect(paragraph.textDirection, TextDirection.ltr);
    expect(
      tester.widget<Text>(find.text(fahadText)).style?.fontFamily,
      'Montserrat',
    );
  });

  group('a reply sits under its comment\'s text', () {
    for (final locale in const [Locale('en'), Locale('ar')]) {
      testWidgets(locale.languageCode, (tester) async {
        await _pump(tester, testReply(author: sara), locale: locale);

        final row = tester.getRect(find.byType(CommentRow));
        final avatar = tester.getRect(find.byType(QeranMonogram));
        final inset = locale.languageCode == 'ar'
            ? row.right - avatar.right
            : avatar.left - row.left;
        expect(inset, CommentRow.replyIndent);
        expect(avatar.width, CommentRow.replyAvatarSize);
      });
    }
  });

  group('Like', () {
    testWidgets('the word alone at 0; the count beside it after', (
      tester,
    ) async {
      await _pump(tester, testComment());
      expect(find.text('Like'), findsOneWidget);
      expect(find.text('0'), findsNothing);

      await _pump(tester, testComment(likeCount: 12));
      expect(find.text('Like'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('liked: a filled heart in gold-deep', (tester) async {
      await _pump(tester, testComment(likeCount: 1, likedByMe: true));

      final heart = tester.widget<Icon>(find.byIcon(Icons.favorite_rounded));
      expect(heart.color, QeranColors.goldDeep);
    });

    testWidgets('read-only: dimmed, and still answers a tap (D9)', (
      tester,
    ) async {
      var taps = 0;
      await _pump(tester, testComment(), readOnly: true, onLike: () => taps++);

      final dimmer = tester.widget<Opacity>(
        find.ancestor(of: find.text('Like'), matching: find.byType(Opacity)),
      );
      expect(dimmer.opacity, 0.4);
      await tester.tap(find.text('Like'));
      expect(taps, 1);
    });

    testWidgets('its tap area is 44 high, its heart in line with the text', (
      tester,
    ) async {
      await _pump(tester, testComment());

      final area = tester.getRect(
        find.ancestor(of: find.text('Like'), matching: find.byType(InkWell)),
      );
      expect(area.height, 44);
      expect(
        tester.getTopLeft(find.byIcon(Icons.favorite_border_rounded)).dx,
        tester.getTopLeft(find.text(saraText)).dx,
      );
    });
  });
}
