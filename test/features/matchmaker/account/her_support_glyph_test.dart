import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/account/presentation/widgets/matchmaker_account_body.dart';
import 'package:qeran/features/settings/presentation/widgets/settings_row.dart';

import '../../../core/shipped_strings_rig.dart';
import 'matchmaker_me_fixtures.dart';

/// D3: Help & support on her Account wears the help glyph, as the member's
/// Profile does — the chat bubble belongs to chat.
void main() {
  setUpAll(initShippedStrings);

  for (final (locale, title) in const [
    (Locale('ar'), 'المساعدة والدعم'),
    (Locale('en'), 'Help & support'),
  ]) {
    testWidgets('the support row [${locale.languageCode}]', (tester) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpShippedStrings(
        tester,
        locale,
        child: MatchmakerAccountBody(
          me: meWith(),
          onEditName: () {},
          onChangePassword: () {},
          onLanguage: () {},
          onNotifications: () {},
          onSupport: () {},
          onTerms: () {},
          onAffiliate: () {},
          onDeactivate: () {},
          onDeleteAccount: () {},
          onLogout: () {},
          loadErrorKey: null,
          onRetryLoad: () {},
          bottomReserve: 0,
        ),
      );

      final row = tester.widget<SettingsRow>(
        find.ancestor(of: find.text(title), matching: find.byType(SettingsRow)),
      );
      expect(row.icon, Icons.help_outline_rounded);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
    });
  }
}
