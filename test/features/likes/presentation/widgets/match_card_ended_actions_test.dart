import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/formal_step_status.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_case_status.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/pending_formal_step.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_direction.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_pending.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_status.dart';
import 'package:qeran/features/likes/presentation/widgets/match_pending_countdown_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'match_card_copy_harness.dart';

/// What a card stops offering once its journey has ended.
///
/// Sub-step 6 made an ended card SAY it had ended; every button on it stayed
/// live. The formal-step CTA had a documented `CASE_NOT_ACTIVE` waiting for
/// it, so the card invited a tap the server was always going to refuse — and
/// the helper line under it went on promising a meeting nobody was arranging.
///
/// One flag on the scaffold withdraws the whole primary region. These tests
/// pin BOTH halves of that: what goes, and what deliberately stays.
///
/// The countdown chip was the third thing that had to go, found after the
/// fact: it lives in the HEADER, so 7b's guard walked straight past it and an
/// ended case went on ticking toward a response nobody could give.
PendingFormalStep _awaitingMe() => PendingFormalStep(
  id: 55,
  likeRequestId: 1,
  status: FormalStepStatus.pending,
  direction: 'Received',
  requestedByMe: false,
  canAccept: true,
  canReject: true,
  remainingSeconds: 3600,
  createdAt: DateTime.utc(2026),
  expiresAt: DateTime.utc(2099),
);

PhotoExchangePending _incomingPhotos() => PhotoExchangePending(
  id: 5,
  likeRequestId: 1,
  initiatorId: 'them',
  responderId: 'me',
  status: PhotoExchangeStatus.pending,
  statusCode: 0,
  remainingSeconds: 3600,
  createdAt: DateTime.utc(2026),
  expiresAt: DateTime.utc(2099),
  direction: PhotoExchangeDirection.received,
  requestedByMe: false,
  canAccept: true,
  canReject: true,
);

const _ar = Locale('ar');

Finder _text(String key) => find.text(shipped(_ar, key));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await loadShippedFonts();
    await EasyLocalization.ensureInitialized();
  });

  group('an ended case withdraws its actions', () {
    testWidgets('stage 0 — the photo-exchange CTA goes', (tester) async {
      await pumpMatchCard(
        tester,
        card: copyCard(
          MatchStage.waitingForPhotoExchange,
          caseStatus: MatchCaseStatus.cancelled,
        ),
      );

      expect(_text('matches_stage_waiting_photos_cta'), findsNothing);
    });

    testWidgets('stage 0 — the accept/decline pair goes', (tester) async {
      await pumpMatchCard(
        tester,
        card: copyCard(
          MatchStage.waitingForPhotoExchange,
          caseStatus: MatchCaseStatus.cancelled,
          pendingPhotoExchange: _incomingPhotos(),
        ),
      );

      expect(_text('matches_photo_exchange_action_accept'), findsNothing);
      expect(_text('matches_photo_exchange_action_reject'), findsNothing);
    });

    testWidgets('stage 1/2 — the formal-step CTA goes', (tester) async {
      for (final stage in const [
        MatchStage.photosExchanged,
        MatchStage.matchmakerEngaged,
      ]) {
        await tester.pumpWidget(const SizedBox());
        await pumpMatchCard(
          tester,
          card: copyCard(stage, caseStatus: MatchCaseStatus.failed),
        );

        expect(
          _text('matches_formal_step_cta'),
          findsNothing,
          reason: stage.name,
        );
      }
    });

    // THE one a `caseStatus`-only gate would miss: declining moves the STAGE
    // and leaves the status Active, so every other row in this file passes
    // such a gate and only this one fails.
    testWidgets('a declined step withdraws its own accept/decline', (
      tester,
    ) async {
      await pumpMatchCard(
        tester,
        card: copyCard(
          MatchStage.matchmakerEngaged,
          caseStage: MatchCaseStage.formalStepRejected,
          pendingFormalStep: _awaitingMe(),
        ),
      );

      expect(_text('matches_formal_step_action_accept'), findsNothing);
      expect(_text('matches_formal_step_action_reject'), findsNothing);
    });

    // The fifth lie, and the reason the flag sits on the scaffold rather than
    // at each caller: the helper is a SEPARATE `if` from the button it
    // captions — it has to be, since the responder state has buttons and no
    // helper — so guarding only the button withdraws the action and leaves
    // its caption promising a meeting nobody is arranging.
    testWidgets('the helper line goes with the button it captions', (
      tester,
    ) async {
      await pumpMatchCard(
        tester,
        card: copyCard(
          MatchStage.matchmakerEngaged,
          caseStatus: MatchCaseStatus.cancelled,
        ),
      );

    });
  });

  group('and what it deliberately keeps', () {
    // Asking the matchmaker is exactly what a member whose case just ended may
    // want to do — the server's own closing notice invites it. It is the only
    // thing in `secondaryActions`, which is why that list survives untouched.
    testWidgets('the matchmaker inquiry survives', (tester) async {
      await pumpMatchCard(
        tester,
        card: copyCard(
          MatchStage.waitingForPhotoExchange,
          caseStatus: MatchCaseStatus.cancelled,
        ),
      );

      expect(_text('matches_inquiry_cta'), findsOneWidget);
    });

    // Replaced, not removed: a card with no status line at all reads as broken
    // rather than as finished.
    testWidgets('the status line is replaced, not removed', (tester) async {
      await pumpMatchCard(
        tester,
        card: copyCard(
          MatchStage.waitingForPhotoExchange,
          caseStatus: MatchCaseStatus.cancelled,
        ),
      );

      expect(_text('matches_stage_ended_subtitle'), findsOneWidget);
      expect(_text('matches_stage_waiting_photos_title'), findsNothing);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('the journey still reports the ending', (tester) async {
      await pumpMatchCard(
        tester,
        card: copyCard(
          MatchStage.photosExchanged,
          caseStatus: MatchCaseStatus.cancelled,
        ),
      );

      expect(_text('matches_journey_ended'), findsOneWidget);
    });
  });

  // The other half of every assertion above. Without these, withdrawing the
  // primary region unconditionally would pass the whole first group.
  group('a running case keeps everything', () {
    testWidgets('stage 0 keeps its CTA, its inquiry and its own status', (
      tester,
    ) async {
      await pumpMatchCard(
        tester,
        card: copyCard(MatchStage.waitingForPhotoExchange),
      );

      expect(_text('matches_stage_waiting_photos_cta'), findsOneWidget);
      expect(_text('matches_inquiry_cta'), findsOneWidget);
      expect(_text('matches_stage_waiting_photos_title'), findsOneWidget);
      expect(_text('matches_stage_ended_subtitle'), findsNothing);
    });

    testWidgets('stage 2 keeps its formal CTA', (tester) async {
      await pumpMatchCard(
        tester,
        card: copyCard(MatchStage.matchmakerEngaged),
      );

      expect(_text('matches_formal_step_cta'), findsOneWidget);
    });

    // A lapsed formal step is NOT an ending — the matchmaker can still pick
    // the couple up — so unlike its declined twin above this card keeps its
    // button and takes the refusal from the server.
    testWidgets('a lapsed formal step keeps its button', (tester) async {
      await pumpMatchCard(
        tester,
        card: copyCard(
          MatchStage.matchmakerEngaged,
          caseStage: MatchCaseStage.formalStepExpired,
        ),
      );

      expect(_text('matches_formal_step_cta'), findsOneWidget);
    });
  });

  // The new line has to survive the narrowest phone, in both languages — the
  // floor 6c established for every other shipped string on this card.
  group('the ended status line fits at 320dp', () {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      testWidgets('[${locale.languageCode}]', (tester) async {
        await pumpMatchCard(
          tester,
          card: copyCard(
            MatchStage.matchmakerEngaged,
            caseStatus: MatchCaseStatus.cancelled,
          ),
          locale: locale,
          size: const Size(320, 900),
        );

        final label = find.text(
          shipped(locale, 'matches_stage_ended_subtitle'),
        );
        expect(label, findsOneWidget, reason: 'ended subtitle not rendered');
        expect(
          isTruncated(tester, label),
          isFalse,
          reason: 'ended subtitle truncates at 320dp in ${locale.languageCode}',
        );
      });
    }
  });

  // The chip is not an action, so 7b's guard — which covers the primary
  // region — never touched it. On a card whose case has ended it was the last
  // live thing on screen, counting toward a deadline that governs nothing.
  //
  // Whether the server keeps sending a pending block past a cancel is an open
  // question with Tariq. It does not change this: the card has never trusted
  // the presence of the block, only the clock, and now not even the clock once
  // the case is over.
  group('an ended case stops counting down', () {
    // The sender card carries NO buttons at all — measured, not assumed — so
    // here the chip is not merely inconsistent with the rest of the card, it
    // IS the rest of the card.
    testWidgets('stage 0, the request I sent', (tester) async {
      await pumpMatchCard(
        tester,
        card: copyCard(
          MatchStage.waitingForPhotoExchange,
          caseStatus: MatchCaseStatus.cancelled,
          pendingPhotoExchange: livePhotoRequestFromMe(),
        ),
      );

      expect(find.byType(MatchPendingCountdownChip), findsNothing);
    });

    testWidgets('stage 0, a request I could have answered', (tester) async {
      await pumpMatchCard(
        tester,
        card: copyCard(
          MatchStage.waitingForPhotoExchange,
          caseStatus: MatchCaseStatus.cancelled,
          pendingPhotoExchange: _incomingPhotos(),
        ),
      );

      expect(find.byType(MatchPendingCountdownChip), findsNothing);
    });

    testWidgets('the matchmaker recorded «لم ينجح»', (tester) async {
      await pumpMatchCard(
        tester,
        card: copyCard(
          MatchStage.waitingForPhotoExchange,
          caseStatus: MatchCaseStatus.failed,
          pendingPhotoExchange: livePhotoRequestFromMe(),
        ),
      );

      expect(find.byType(MatchPendingCountdownChip), findsNothing);
    });

    // THE one a status-only gate misses, and the second time this exact case
    // has caught a half-written rule: declining the formal step moves the
    // STAGE and leaves `caseStatus` Active. A gate reading status alone lets
    // the formal-step countdown run on after the ending it announces.
    testWidgets('the formal step was declined — status still Active', (
      tester,
    ) async {
      await pumpMatchCard(
        tester,
        card: copyCard(
          MatchStage.photosExchanged,
          caseStage: MatchCaseStage.formalStepRejected,
          pendingFormalStep: _awaitingMe(),
        ),
      );

      expect(find.byType(MatchPendingCountdownChip), findsNothing);
    });

    // Guards the guard. Without it, deleting the chip outright passes every
    // assertion above — and the four of them would be pinning nothing.
    testWidgets('a RUNNING case still counts down', (tester) async {
      await pumpMatchCard(
        tester,
        card: copyCard(
          MatchStage.waitingForPhotoExchange,
          pendingPhotoExchange: livePhotoRequestFromMe(),
        ),
      );

      expect(find.byType(MatchPendingCountdownChip), findsOneWidget);
    });
  });
}
