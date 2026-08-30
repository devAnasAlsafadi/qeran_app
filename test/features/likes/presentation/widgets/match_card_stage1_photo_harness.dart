import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_case_status.dart';
import 'package:qeran/features/likes/domain/entities/match_image.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/presentation/widgets/match_card_avatar.dart';
import 'package:qeran/features/likes/presentation/widgets/match_card_stage1.dart';

/// Shared rig for the two halves of the stage-1 photo gate: what a RUNNING
/// case offers, and what a case that is over withdraws.
///
/// Split from the tests because both halves need the same card, the same
/// pump and the same "did the avatar open the gallery" probe, and the two
/// files that use them are each near the 200-line cap on their own.
///
/// A stub loader, so every key renders as its own name — these assertions
/// are about which controls exist, not about how the copy fits.
class PhotoGateLoader extends AssetLoader {
  const PhotoGateLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

/// The endings, and the one success. Every one takes the photos away —
/// `matchJourneyHasEnded` covers the first three, and the marriage is
/// excluded from that predicate on purpose so a wedding never draws as a
/// failure, which is exactly why it has to be named separately here.
const closedCases = [
  (
    'cancelled',
    MatchCaseStage.photoExchangeAccepted,
    MatchCaseStatus.cancelled,
  ),
  ('failed', MatchCaseStage.photoExchangeAccepted, MatchCaseStatus.failed),
  (
    'declined formal step',
    MatchCaseStage.formalStepRejected,
    MatchCaseStatus.active,
  ),
  (
    'marriage completed',
    MatchCaseStage.marriageCompleted,
    MatchCaseStatus.completed,
  ),
];

MatchCard photoCard({
  required bool isBlurred,
  MatchCaseStage caseStage = MatchCaseStage.photoExchangeAccepted,
  MatchCaseStatus caseStatus = MatchCaseStatus.active,
}) => MatchCard(
  likeRequestId: 1,
  otherUserId: 'u1',
  otherUserName: 'User',
  images: [
    MatchImage(
      id: '7',
      url: 'https://example.invalid/protected.jpg',
      isProfile: true,
      isBlurred: isBlurred,
    ),
  ],
  stage: MatchStage.photosExchanged,
  pendingPhotoExchange: null,
  formalRequest: null,
  conversationId: null,
  caseStage: caseStage,
  caseStatus: caseStatus,
);

/// Taps the avatar and reports how many times the gallery opened.
///
/// Behavioural on purpose: reading `onTap` for null would pass a gate that
/// wires a live handler behind a disabled-looking avatar, and the avatar is
/// the entry point a button-only gate leaves open.
Future<int> opensAfterTappingAvatar(WidgetTester tester, MatchCard card) async {
  var opens = 0;
  await pumpStage1(tester, card, onOpen: () => opens++);
  await tester.tap(find.byType(MatchCardAvatar), warnIfMissed: false);
  await tester.pumpAndSettle();
  return opens;
}

Future<void> pumpStage1(
  WidgetTester tester,
  MatchCard card, {
  VoidCallback? onOpen,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      path: 'unused',
      assetLoader: const PhotoGateLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MatchCardStage1(
                card: card,
                onOpenGallery: onOpen ?? () {},
                onFormalStep: () {},
                isFormalStepSending: false,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
