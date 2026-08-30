import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/features/likes/domain/entities/formal_step_status.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/pending_formal_step.dart';
import 'package:qeran/features/likes/presentation/widgets/match_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Found on device: the member APPROVES the formal step, and her own card
/// then reads «بانتظار موافقة الطرف الآخر» — the person who granted the
/// approval told she is waiting for one.
///
/// It was never a refresh problem. The accept path reloads the list and the
/// reloaded row is right; the READING of it was wrong. `hasRequestedFormalStep`
/// is true at every post-approval stage, and the payload it reads carries no
/// perspective at all — `pendingFormalStep` goes null on approval and
/// `caseStage` belongs to the CASE — so the retired sent button said the same
/// wrong thing to BOTH members.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

const _sent = 'likes.matches_formal_step_sent';
const _cta = 'likes.matches_formal_step_cta';
const _approved = 'likes.matches_formal_step_approved';

/// Reachable only by an approval. The button is wrong at all three; only the
/// first has copy of its own, the other two keep their stage subtitle until
/// the owner settles what they should say.
const _pastApproval = [
  MatchCaseStage.awaitingMatchmakerCoordination,
  MatchCaseStage.parentsVisited,
  MatchCaseStage.marriageCompleted,
];

const _hosts = [MatchStage.photosExchanged, MatchStage.matchmakerEngaged];

MatchCard _card(
  MatchCaseStage caseStage, {
  MatchStage host = MatchStage.photosExchanged,
  PendingFormalStep? pending,
}) => MatchCard(
  likeRequestId: 1,
  otherUserId: 'u1',
  otherUserName: 'نور',
  images: const [],
  stage: host,
  pendingPhotoExchange: null,
  formalRequest: null,
  conversationId: null,
  caseStage: caseStage,
  pendingFormalStep: pending,
);

/// An ANSWERED block, so neither fixture reaches the responder branch: the
/// only thing that differs between the two is who asked.
PendingFormalStep _answered({required bool requestedByMe}) => PendingFormalStep(
  id: 5,
  likeRequestId: 1,
  status: FormalStepStatus.accepted,
  remainingSeconds: 0,
  createdAt: DateTime.utc(2026, 8, 1),
  expiresAt: DateTime.utc(2026, 8, 3),
  direction: requestedByMe ? 'Sent' : 'Received',
  requestedByMe: requestedByMe,
  canAccept: false,
  canReject: false,
);

Future<void> _pump(WidgetTester tester, MatchCard card) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      startLocale: const Locale('ar'),
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MatchCardWidget(card: card, onFormalStep: () {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<String> _texts(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? '')
    .toList();

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final host in _hosts) {
    group(host.name, () {
      for (final stage in _pastApproval) {
        testWidgets('${stage.name} claims no wait on the other member', (
          tester,
        ) async {
          await _pump(tester, _card(stage, host: host));

          expect(
            find.text(_sent),
            findsNothing,
            reason:
                'the retired sent button survived at ${stage.name}. The step '
                'was approved; nobody is waiting on an approval.',
          );
          expect(find.text(_cta), findsNothing);
        });

        testWidgets('${stage.name} offers no button at all', (tester) async {
          await _pump(tester, _card(stage, host: host));

          expect(
            find.byType(QeranButton),
            findsNothing,
            reason:
                'the approved state is a status line, not a control — a '
                'disabled button is still a button.',
          );
        });
      }

      testWidgets('the approval gets said in words', (tester) async {
        await _pump(
          tester,
          _card(MatchCaseStage.awaitingMatchmakerCoordination, host: host),
        );

        expect(find.text(_approved), findsOneWidget);
      });

      // The other two are their own states, not the moment after approval:
      // «تمت الموافقة. ستتواصل معك الخطّابة» is stale by parentsVisited and
      // false once the marriage happened. Their subtitle stands until the
      // owner says what should replace it.
      for (final stage in const [
        MatchCaseStage.parentsVisited,
        MatchCaseStage.marriageCompleted,
      ]) {
        testWidgets('${stage.name} does not borrow the approval line', (
          tester,
        ) async {
          await _pump(tester, _card(stage, host: host));

          expect(find.text(_approved), findsNothing);
        });
      }
    });
  }

  // THE one. The original bug was a perspective read off a payload that has
  // none, so the sender's card and the accepter's card must be
  // indistinguishable here — any branch on `requestedByMe` is the same bug
  // returning under a new name.
  group('both members read the same card', () {
    for (final stage in _pastApproval) {
      testWidgets('${stage.name} renders identically either way', (
        tester,
      ) async {
        await _pump(
          tester,
          _card(stage, pending: _answered(requestedByMe: true)),
        );
        final asSender = _texts(tester);

        await _pump(
          tester,
          _card(stage, pending: _answered(requestedByMe: false)),
        );

        expect(_texts(tester), asSender);
        expect(asSender, isNot(contains(_sent)));
      });
    }
  });
}
