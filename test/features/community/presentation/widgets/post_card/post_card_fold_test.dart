import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/community_post_card.dart';

import '../../../../../core/shipped_strings_rig.dart';
import '../../../fixtures/community_post_fixtures.dart';

/// «عرض أقل» on a card in a list: when the card's top had gone above the
/// screen the list comes back to it; when it hadn't, nothing moves.
void main() {
  setUpAll(initShippedStrings);

  /// A list with [above] points before the card, and room after it; the
  /// card's [text] (a long one by default) opened.
  Future<ScrollController> pumpList(
    WidgetTester tester, {
    required double above,
    String? text,
  }) async {
    final list = ScrollController();
    addTearDown(list.dispose);
    await pumpShippedStrings(
      tester,
      const Locale('en'),
      child: ListView(
        controller: list,
        children: [
          SizedBox(height: above),
          CommunityPostCard(post: testPost(text: text ?? longText)),
          const SizedBox(height: 1500),
        ],
      ),
    );
    await tester.tap(find.text('See more'));
    await tester.pumpAndSettle();
    return list;
  }

  double cardTop(WidgetTester tester) =>
      tester.getTopLeft(find.byType(CommunityPostCard)).dy;

  testWidgets('its top above the screen: the list scrolls back to it', (
    tester,
  ) async {
    final list = await pumpList(tester, above: 300);
    // «See less» brought to the middle of the screen, the card's top above.
    list.jumpTo(
      list.offset + tester.getTopLeft(find.text('See less')).dy - 300,
    );
    await tester.pump();
    expect(cardTop(tester), lessThan(0));

    await tester.tap(find.text('See less'));
    await tester.pumpAndSettle();

    expect(list.offset, 300);
    expect(cardTop(tester), 0);
    expect(find.text('See more'), findsOneWidget);
  });

  testWidgets('its top in view: nothing moves', (tester) async {
    // Six short lines: past four, and short enough to stay in view opened.
    final six = List.filled(6, 'سطر').join('\n');
    final list = await pumpList(tester, above: 40, text: six);
    final before = list.offset;
    expect(cardTop(tester), greaterThanOrEqualTo(0));
    expect(tester.getBottomLeft(find.text('See less')).dy, lessThan(600));

    await tester.tap(find.text('See less'));
    await tester.pumpAndSettle();

    expect(list.offset, before);
  });
}
