import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/features/matchmaker/notifications/data/models/matchmaker_notification_model.dart';
import 'package:qeran/features/matchmaker/notifications/domain/entities/matchmaker_notification.dart';
import 'package:qeran/features/matchmaker/notifications/presentation/widgets/matchmaker_notification_tile.dart';

import '../../../core/shipped_strings_rig.dart';
import 'her_community_notifications.dart';

/// The tile's leading chip around [icon]: its ground and the glyph's colour.
(Color, Color) _chip(WidgetTester tester, IconData icon) {
  final chip = tester.widget<Container>(
    find
        .ancestor(of: find.byIcon(icon), matching: find.byType(Container))
        .first,
  );
  final glyph = tester.widget<Icon>(find.byIcon(icon));
  return ((chip.decoration! as BoxDecoration).color!, glyph.color!);
}

/// Her inbox's Community tiles (F1, D31): the server's title and body, the
/// comment bubble and the reply arrow on the wine tint, and the report's
/// filled flag on soft gold (Q8).
void main() {
  setUpAll(initShippedStrings);

  test('the wire type «Community» is hers now', () {
    final model = MatchmakerNotificationModel.fromJson(const {
      'id': 4,
      'type': 'Community',
      'data': '{"action":"community_report","postId":"5"}',
    });
    expect(model.toEntity().type, MatchmakerNotificationType.community);
    expect(model.toEntity().data['action'], 'community_report');
  });

  for (final arabic in [true, false]) {
    final language = arabic ? 'ar' : 'en';
    testWidgets('[$language] the three, each with its glyph and tone', (
      tester,
    ) async {
      await pumpShippedStrings(
        tester,
        Locale(language),
        child: Column(
          children: [
            for (final n in [herComment, herReply, herReport])
              MatchmakerNotificationTile(notification: n, isArabic: arabic),
          ],
        ),
      );

      for (final n in [herComment, herReply, herReport]) {
        expect(find.text(n.title(isArabic: arabic)), findsOneWidget);
        expect(find.text(n.body(isArabic: arabic)), findsOneWidget);
      }
      const wine = (QeranColors.wine08, QeranColors.wine);
      expect(_chip(tester, Icons.mode_comment_outlined), wine);
      expect(_chip(tester, Icons.reply_rounded), wine);
      expect(_chip(tester, Icons.flag_rounded), (
        QeranColors.gold20,
        QeranColors.goldDeep,
      ));
    });
  }
}
