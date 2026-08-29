import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/features/likes/domain/entities/formal_step_status.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/pending_formal_step.dart';
import 'package:qeran/features/likes/presentation/widgets/match_card.dart';
import 'package:qeran/features/likes/presentation/widgets/match_pending_countdown_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'match_card_copy_harness.dart';

/// Where the countdown sits, and why it is not in the header.
///
/// The chip reports on a REQUEST — how long is left to answer one. It spent
/// two revisions inside the identity block anyway: first on the name row,
/// where it clipped real names, then on its own line under the name, where it
/// still took 144.8dp of a 170dp column to say something about neither the
/// avatar above it nor the person beside it.
///
/// It now has a full-width line of the card's own, between the status line and
/// the actions. The obvious alternative — anchor it above the accept/decline
/// buttons — was rejected because it is undefined in two of the five states
/// that render a chip: the photo-exchange SENDER card carries no buttons at
/// all, and an ended case withdraws the ones it had. A slot that exists only
/// sometimes makes the chip move by state, which is what the header layout was
/// chosen to avoid in the first place.
PendingFormalStep _formal({required bool mine}) => PendingFormalStep(
  id: 9,
  likeRequestId: 1,
  status: FormalStepStatus.pending,
  remainingSeconds: kWidestCountdownSeconds,
  createdAt: DateTime.utc(2026),
  expiresAt: DateTime.utc(2099),
  direction: mine ? 'Sent' : 'Received',
  requestedByMe: mine,
  canAccept: !mine,
  canReject: !mine,
);

double _midY(WidgetTester tester, Finder f) => tester.getCenter(f).dy;

/// How far the leading edge of [f] sits from the card's leading edge, read in
/// whichever direction the locale runs. Mirroring makes this the only
/// comparable measure between the two languages.
double _leadingInset(WidgetTester tester, Finder f, {required bool rtl}) {
  final box = tester.getRect(f);
  final card = tester.getRect(find.byType(MatchCardWidget));
  return rtl ? card.right - box.right : box.left - card.left;
}

Finder get _chip => find.byType(MatchPendingCountdownChip);

const _ar = Locale('ar');

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await loadShippedFonts();
    await EasyLocalization.ensureInitialized();
  });

  group('the countdown sits below the status line and above the actions', () {
    // The card from the screenshot that started this: an incoming photo
    // exchange. Here the new slot lands exactly where the instinct wanted it —
    // directly above the buttons — but arrives without a conditional.
    testWidgets('stage 0, a request I can answer', (tester) async {
      await pumpMatchCard(tester, card: cardAwaitingMyResponse());

      final status = _midY(
        tester,
        find.text(shipped(_ar, 'matches_stage_waiting_photos_title')),
      );
      final accept = _midY(
        tester,
        find.text(shipped(_ar, 'matches_photo_exchange_action_accept')),
      );

      expect(_midY(tester, _chip), greaterThan(status));
      expect(_midY(tester, _chip), lessThan(accept));
    });

    // The state the placement had to be chosen for. This card has NO buttons —
    // measured, not assumed — so there is nothing here for a chip anchored
    // above the actions to be above. Below the status line it reads as one
    // thought: what is awaited, then how long is left.
    testWidgets('stage 0, the request I sent has no buttons at all', (
      tester,
    ) async {
      await pumpMatchCard(
        tester,
        card: copyCard(
          MatchStage.waitingForPhotoExchange,
          pendingPhotoExchange: livePhotoRequestFromMe(),
        ),
      );

      final status = _midY(
        tester,
        find.text(shipped(_ar, 'matches_stage_waiting_photos_pending')),
      );

      expect(_midY(tester, _chip), greaterThan(status));
    });

    for (final mine in const [true, false]) {
      testWidgets('the formal step keeps the same order, mine=$mine', (
        tester,
      ) async {
        await pumpMatchCard(
          tester,
          card: copyCard(
            MatchStage.photosExchanged,
            pendingFormalStep: _formal(mine: mine),
          ),
        );

        // The status line's icon is the last thing the identity block draws.
        expect(_chip, findsOneWidget);
        expect(
          _midY(tester, _chip),
          greaterThan(_midY(tester, find.byType(Icon).first)),
        );
      });
    }
  });

  // The mirroring guard. A hardcoded `Alignment.centerLeft` renders
  // identically to `AlignmentDirectional.centerStart` in English and puts the
  // chip on the wrong edge in Arabic — the app's DEFAULT language, and the one
  // an English-first review never looks at.
  group('it hugs the leading edge of the card, in either direction', () {
    for (final width in const [320.0, 360.0]) {
      testWidgets('${width.toInt()}dp reads the same inset in ar and en', (
        tester,
      ) async {
        final insets = <String, double>{};
        for (final locale in const [Locale('ar'), Locale('en')]) {
          await tester.pumpWidget(const SizedBox());
          await pumpMatchCard(
            tester,
            card: copyCard(
              MatchStage.waitingForPhotoExchange,
              name: kLongNames[locale.languageCode]!,
              pendingPhotoExchange: livePhotoRequestFromMe(),
            ),
            locale: locale,
            size: Size(width, 900),
          );
          insets[locale.languageCode] = _leadingInset(
            tester,
            _chip,
            rtl: locale.languageCode == 'ar',
          );
        }

        expect(
          insets['ar'],
          closeTo(insets['en']!, 0.5),
          reason:
              'the chip sits ${insets['ar']}dp from the leading edge in ar and '
              '${insets['en']}dp in en. Mirroring should make these identical; '
              'a hardcoded left edge is how they come apart.',
        );
      });
    }

    // And it is the CARD's edge, not the name column's — the difference
    // between "the card has a countdown" and "this person has a countdown".
    //
    // Measured against the BUTTON's edge rather than against the name's. The
    // first version of this test only asked the chip to start before the name
    // did, and an indent halfway between the two passed it: the name is pushed
    // in by the avatar, so there is a wide band of visibly-wrong positions
    // that still beat it. The buttons start exactly where the card's content
    // starts, which is the line the chip is supposed to share.
    testWidgets('its leading edge matches the buttons, not the name', (
      tester,
    ) async {
      await pumpMatchCard(tester, card: cardAwaitingMyResponse());

      final chip = _leadingInset(tester, _chip, rtl: true);
      final button = _leadingInset(
        tester,
        find.ancestor(
          of: find.text(shipped(_ar, 'matches_photo_exchange_action_reject')),
          matching: find.byType(QeranButton),
        ),
        rtl: true,
      );

      expect(
        chip,
        closeTo(button, 0.5),
        reason:
            'the chip starts ${chip}dp in and the buttons start ${button}dp '
            'in. Anything but flush means it is still indented to something '
            'in the identity block.',
      );
    });
  });

  // Debt #22, closed by the move rather than by a fix of its own. In the name
  // column the chip had 130dp for the 144.8dp it wants and overflowed by 15px;
  // the full-width line gives it the room. 280dp is BELOW the 320dp floor this
  // project supports — kept only because this is where the overflow was found,
  // and a width that used to break is worth one assertion.
  testWidgets('280dp no longer overflows', (tester) async {
    await pumpMatchCard(
      tester,
      card: copyCard(
        MatchStage.waitingForPhotoExchange,
        name: kLongNames['ar']!,
        pendingPhotoExchange: livePhotoRequestFromMe(),
      ),
      size: const Size(280, 900),
    );

    expect(_chip, findsOneWidget);
    expect(tester.getSize(_chip).width, closeTo(144.8, 1.0));
  });
}
