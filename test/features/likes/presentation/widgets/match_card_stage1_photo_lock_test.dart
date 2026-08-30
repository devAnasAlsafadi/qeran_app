import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'match_card_stage1_photo_harness.dart';

/// Photos belong to a case that is still running. The moment one ends — by
/// either member cancelling, the matchmaker recording a failure, a declined
/// formal step, or the marriage completing — the card stops offering them
/// and stops mentioning them.
///
/// ⚠️ This is the UX half of a boundary the client does not own. The bytes
/// are the server's to refuse, and the unblurred URL is in the member's
/// payload before any of this renders. These tests pin that the card stops
/// OFFERING what an over case cannot support, never that it stops anyone
/// determined — the revocation itself is Tariq's.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  // THE pair. An over case must expose no way in by EITHER route: gating the
  // button alone leaves the avatar as a silent back door that nothing else
  // here would notice.
  group('a case that is over', () {
    for (final (name, stage, status) in closedCases) {
      MatchCard closed({required bool isBlurred}) =>
          photoCard(isBlurred: isBlurred, caseStage: stage, caseStatus: status);

      testWidgets('$name withdraws the reveal button', (tester) async {
        await pumpStage1(tester, closed(isBlurred: false));

        expect(
          find.text(LocaleKeys.likes_matches_photo_view_show),
          findsNothing,
        );
      });

      testWidgets('$name withdraws the avatar route', (tester) async {
        expect(
          await opensAfterTappingAvatar(tester, closed(isBlurred: false)),
          isZero,
          reason:
              '$name: the button is gone but the avatar still opens the '
              'gallery — the back door a button-only gate leaves.',
        );
      });

      // Nothing to say about photos on a case with nothing left to do. The
      // member who never looked is not told they missed it, and the member
      // who did is not reminded on a card that has moved on.
      testWidgets('$name says nothing about photos at all', (tester) async {
        await pumpStage1(tester, closed(isBlurred: true));

        expect(
          find.text(LocaleKeys.likes_matches_photo_view_done),
          findsNothing,
        );
        expect(
          find.text(LocaleKeys.likes_matches_photo_view_expired),
          findsNothing,
        );
      });
    }
  });
}
