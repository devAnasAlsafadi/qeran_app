import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_confirm_dialog.dart';
import 'package:qeran/features/likes/domain/entities/formal_step_status.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_image.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/pending_formal_step.dart';
import 'package:qeran/features/likes/presentation/widgets/match_card.dart';
import 'package:qeran/features/likes/presentation/widgets/match_pending_countdown_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'match_card_copy_harness.dart';

/// The receiver's card. Which of the three formal-step states a card shows is
/// the server's answer, and every wrong reading is quiet: a member invited to
/// approve their own request, a sender handed accept/decline buttons, or a
/// decline going through with no confirmation.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

const _cta = 'likes.matches_formal_step_cta';
const _sent = 'likes.matches_formal_step_sent';
const _accept = 'likes.matches_formal_step_action_accept';
const _reject = 'likes.matches_formal_step_action_reject';
const _awaitingYou = 'likes.matches_formal_step_awaiting_you';
const _confirmAction = 'likes.matches_case_end_confirm_action';

PendingFormalStep _pending({
  required bool requestedByMe,
  bool canAccept = true,
  bool canReject = true,
  bool lapsed = false,
}) {
  final now = DateTime.now().toUtc();
  return PendingFormalStep(
    id: 55,
    likeRequestId: 1,
    status: FormalStepStatus.pending,
    remainingSeconds: lapsed ? 0 : 3600,
    createdAt: now,
    expiresAt: lapsed
        ? now.subtract(const Duration(hours: 1))
        : now.add(const Duration(hours: 47)),
    direction: requestedByMe ? 'Sent' : 'Received',
    requestedByMe: requestedByMe,
    canAccept: canAccept,
    canReject: canReject,
  );
}

MatchCard _card({
  MatchStage stage = MatchStage.photosExchanged,
  MatchCaseStage caseStage = MatchCaseStage.unknown,
  PendingFormalStep? pending,
}) => MatchCard(
  likeRequestId: 1,
  otherUserId: 'u1',
  otherUserName: 'User',
  images: const [
    MatchImage(
      id: '7',
      url: 'https://example.invalid/p.jpg',
      isProfile: true,
      isBlurred: true,
    ),
  ],
  stage: stage,
  pendingPhotoExchange: null,
  formalRequest: null,
  conversationId: null,
  caseStage: caseStage,
  pendingFormalStep: pending,
);

class _Taps {
  final List<int> accepted = [];
  final List<int> rejected = [];
}

Future<_Taps> _pump(
  WidgetTester tester,
  MatchCard card, {
  Locale locale = const Locale('ar'),
}) async {
  final taps = _Taps();
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      startLocale: locale,
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MatchCardWidget(
                card: card,
                onFormalStep: () {},
                onAcceptFormalStep: taps.accepted.add,
                onRejectFormalStep: taps.rejected.add,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return taps;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await loadShippedFonts();
    await EasyLocalization.ensureInitialized();
  });

  group('which state the card shows', () {
    testWidgets('a request I received offers accept and decline', (
      tester,
    ) async {
      await _pump(
        tester,
        _card(
          caseStage: MatchCaseStage.formalStepPending,
          pending: _pending(requestedByMe: false),
        ),
      );

      expect(find.text(_accept), findsOneWidget);
      expect(find.text(_reject), findsOneWidget);
      expect(find.text(_cta), findsNothing);
    });

    // The sender must never be handed the buttons for answering their own
    // request. `canAccept`/`canReject` are the server's verdict, not
    // `requestedByMe` — but on a sent request they all agree.
    testWidgets('a request I sent shows the retired button instead', (
      tester,
    ) async {
      await _pump(
        tester,
        _card(
          caseStage: MatchCaseStage.formalStepPending,
          pending: _pending(
            requestedByMe: true,
            canAccept: false,
            canReject: false,
          ),
        ),
      );

      expect(find.text(_sent), findsOneWidget);
      expect(find.text(_accept), findsNothing);
      expect(find.text(_reject), findsNothing);
    });

    testWidgets('no request at all keeps the CTA', (tester) async {
      await _pump(tester, _card());

      expect(find.text(_cta), findsOneWidget);
      expect(find.text(_accept), findsNothing);
    });

    // A lapsed request keeps arriving as Pending with a real expiresAt until
    // the server sweeps it. Offering buttons the server would refuse is the
    // failure this pins.
    testWidgets('a lapsed request offers nothing to answer', (tester) async {
      await _pump(
        tester,
        _card(
          caseStage: MatchCaseStage.formalStepPending,
          pending: _pending(requestedByMe: false, lapsed: true),
        ),
      );

      expect(find.text(_accept), findsNothing);
      expect(find.text(_reject), findsNothing);
    });

    testWidgets('the responder state reaches stage 2 as well', (tester) async {
      await _pump(
        tester,
        _card(
          stage: MatchStage.matchmakerEngaged,
          caseStage: MatchCaseStage.formalStepPending,
          pending: _pending(requestedByMe: false),
        ),
      );

      expect(find.text(_accept), findsOneWidget);
    });
  });

  group('what the card says around the buttons', () {
    testWidgets('the status line names whose turn it is', (tester) async {
      await _pump(
        tester,
        _card(
          caseStage: MatchCaseStage.formalStepPending,
          pending: _pending(requestedByMe: false),
        ),
      );

      expect(find.text(_awaitingYou), findsOneWidget);
    });

    testWidgets('both sides get the countdown while it is open', (
      tester,
    ) async {
      for (final mine in const [true, false]) {
        await tester.pumpWidget(const SizedBox());
        await _pump(
          tester,
          _card(
            caseStage: MatchCaseStage.formalStepPending,
            pending: _pending(
              requestedByMe: mine,
              canAccept: !mine,
              canReject: !mine,
            ),
          ),
        );

        expect(
          find.byType(MatchPendingCountdownChip),
          findsOneWidget,
          reason: 'requestedByMe=$mine',
        );
      }
    });

    testWidgets('no request means no countdown', (tester) async {
      await _pump(tester, _card());

      expect(find.byType(MatchPendingCountdownChip), findsNothing);
    });
  });

  group('answering', () {
    testWidgets('accept fires straight through with the REQUEST id', (
      tester,
    ) async {
      final taps = await _pump(
        tester,
        _card(
          caseStage: MatchCaseStage.formalStepPending,
          pending: _pending(requestedByMe: false),
        ),
      );

      await tester.tap(find.text(_accept));
      await tester.pumpAndSettle();

      expect(taps.accepted, [55]);
      expect(taps.rejected, isEmpty);
    });

    // Declining ends the case outright, and the button sits directly under
    // accept. A mis-tap must not be able to lose a case.
    testWidgets('decline asks first and does nothing if dismissed', (
      tester,
    ) async {
      final taps = await _pump(
        tester,
        _card(
          caseStage: MatchCaseStage.formalStepPending,
          pending: _pending(requestedByMe: false),
        ),
      );

      await tester.tap(find.text(_reject));
      await tester.pumpAndSettle();

      expect(find.byType(QeranConfirmDialog), findsOneWidget);
      expect(taps.rejected, isEmpty, reason: 'fired before confirming');

      Navigator.of(tester.element(find.byType(QeranConfirmDialog))).pop(false);
      await tester.pumpAndSettle();

      expect(taps.rejected, isEmpty);
    });

    testWidgets('decline goes through once confirmed', (tester) async {
      final taps = await _pump(
        tester,
        _card(
          caseStage: MatchCaseStage.formalStepPending,
          pending: _pending(requestedByMe: false),
        ),
      );

      await tester.tap(find.text(_reject));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_confirmAction));
      await tester.pumpAndSettle();

      expect(taps.rejected, [55]);
      expect(taps.accepted, isEmpty);
    });

    // The server can withdraw one verb without withdrawing the other.
    testWidgets('a withdrawn verb leaves its button dead', (tester) async {
      final taps = await _pump(
        tester,
        _card(
          caseStage: MatchCaseStage.formalStepPending,
          pending: _pending(requestedByMe: false, canAccept: false),
        ),
      );

      await tester.tap(find.text(_accept), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(taps.accepted, isEmpty);
      expect(find.text(_reject), findsOneWidget);
    });
  });

  // The photo-exchange pair puts two Expanded buttons in one row, which
  // leaves ~68dp of text each. «عدم الموافقة وإنهاء التوافق» is more than
  // twice the photo reject it would sit beside, so this pair is stacked — and
  // stacking is only right if it actually clears the labels.
  //
  // 320dp now, the true floor. This group also read "360dp" for the same
  // reason the copy test did — the inset moved and the label was corrected
  // instead of the measurement — and at a real 320dp
  // «matches_formal_step_awaiting_you» overshot its two-line slot by 0.07 of
  // a line. The English was simply verbose: 45 characters for what the Arabic
  // says in 27. It was shortened rather than the guard being left at 360.
  group('the shipped labels fit at 320dp', () {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      final lang = locale.languageCode;

      for (final key in const [
        'matches_formal_step_action_accept',
        'matches_formal_step_action_reject',
        'matches_formal_step_awaiting_you',
      ]) {
        testWidgets('$key is not ellipsised [$lang]', (tester) async {
          await pumpMatchCard(
            tester,
            card: _card(
              caseStage: MatchCaseStage.formalStepPending,
              pending: _pending(requestedByMe: false),
            ),
            locale: locale,
            size: const Size(320, 900),
          );

          final label = find.text(shipped(locale, key));
          expect(label, findsOneWidget, reason: '$key not rendered');
          expect(
            isTruncated(tester, label),
            isFalse,
            reason: '$key truncates at 320dp in $lang',
          );
        });
      }
    }
  });
}
