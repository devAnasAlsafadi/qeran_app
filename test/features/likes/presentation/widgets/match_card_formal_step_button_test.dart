import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/formal_step_status.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_image.dart';
import 'package:qeran/features/likes/domain/entities/pending_formal_step.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/presentation/widgets/match_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `MatchCardSentAction.isEnabled` decides that the formal-step CTA retires
/// once the request is in, but the section has to HONOUR it — and that one
/// line is invisible: drop it and every label, colour and checkmark still
/// reads correctly while the dead button quietly answers taps again.
///
/// "Sent" is driven off the CARD here, not a parameter. It became a server
/// fact in the request commit, and the card is where that fact lives.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

const _cta = 'likes.matches_formal_step_cta';
const _sent = 'likes.matches_formal_step_sent';

/// [isSent] builds the state the server would actually return: an open
/// request this member sent. Nothing here fakes the flag.
MatchCard _card(MatchStage stage, {required bool isSent}) => MatchCard(
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
  caseStage: isSent
      ? MatchCaseStage.formalStepPending
      : MatchCaseStage.photoExchangeAccepted,
  pendingFormalStep: isSent
      ? PendingFormalStep(
          id: 55,
          likeRequestId: 1,
          status: FormalStepStatus.pending,
          remainingSeconds: 3600,
          createdAt: DateTime.now().toUtc(),
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 47)),
          direction: 'Sent',
          requestedByMe: true,
          canAccept: false,
          canReject: false,
        )
      : null,
);

Future<int> _tapsAccepted(
  WidgetTester tester, {
  required MatchStage stage,
  required bool isSent,
}) async {
  var taps = 0;
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
              child: MatchCardWidget(
                card: _card(stage, isSent: isSent),
                onFormalStep: () => taps++,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  final label = find.text(isSent ? _sent : _cta);
  expect(label, findsOneWidget, reason: 'formal CTA not rendered');
  await tester.tap(label, warnIfMissed: false);
  await tester.pumpAndSettle();
  return taps;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final stage in const [
    MatchStage.photosExchanged,
    MatchStage.matchmakerEngaged,
  ]) {
    group(stage.name, () {
      testWidgets('unsent, the CTA fires', (tester) async {
        expect(
          await _tapsAccepted(tester, stage: stage, isSent: false),
          1,
        );
      });

      testWidgets('sent, the button no longer answers', (tester) async {
        expect(
          await _tapsAccepted(tester, stage: stage, isSent: true),
          isZero,
        );
      });
    });
  }
}
