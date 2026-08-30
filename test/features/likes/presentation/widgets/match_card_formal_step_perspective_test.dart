import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/formal_step_status.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/pending_formal_step.dart';
import 'package:qeran/features/likes/presentation/widgets/match_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The post-approval card must look the same to BOTH members.
///
/// Split from `match_card_formal_step_approved_test.dart`, which pins what
/// that card says; this pins that who is reading it cannot change the answer.
/// The original bug was a perspective read off a payload that carries none —
/// `pendingFormalStep` goes null on approval and `caseStage` belongs to the
/// CASE — so any branch on `requestedByMe` at these stages is that bug
/// returning under a new name.

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

const _sent = 'likes.matches_formal_step_sent';

/// Reachable only by an approval.
const _pastApproval = [
  MatchCaseStage.awaitingMatchmakerCoordination,
  MatchCaseStage.parentsVisited,
  MatchCaseStage.marriageCompleted,
];

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
