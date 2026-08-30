import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
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

/// The line each post-approval stage says for itself. Held here as a map
/// rather than one constant so a stage borrowing a neighbour's words is a
/// test failure and not a reading exercise.
const _lines = {
  MatchCaseStage.awaitingMatchmakerCoordination:
      'likes.matches_formal_step_approved',
  MatchCaseStage.parentsVisited: 'likes.matches_formal_step_parents_visited',
  MatchCaseStage.marriageCompleted:
      'likes.matches_formal_step_marriage_completed',
};

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
  pendingFormalStep: null,
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

      // Each stage says its own thing. The approval line is true the moment
      // the step is approved, stale by the family visit, and false once the
      // marriage happened — so a stage wearing a neighbour's words is the
      // same defect as the button that started this, one row up.
      for (final stage in _pastApproval) {
        testWidgets('${stage.name} says its own line and no other', (
          tester,
        ) async {
          await _pump(tester, _card(stage, host: host));

          expect(find.text(_lines[stage]!), findsOneWidget);
          for (final other in _pastApproval.where((s) => s != stage)) {
            expect(
              find.text(_lines[other]!),
              findsNothing,
              reason: '${stage.name} is wearing the line for ${other.name}',
            );
          }
        });
      }
    });
  }
}
