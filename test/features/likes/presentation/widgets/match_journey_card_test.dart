import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/formal_request.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/presentation/widgets/match_journey_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Returns no translations, so `.t(key)` renders the key itself — enough to
/// assert WHICH stage is named without pinning the copy.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

const _liked = 'likes.matches_journey_liked';
const _likeAccepted = 'likes.matches_journey_like_accepted';
const _photoExchange = 'likes.matches_journey_photo_exchange';
const _matchmaker = 'likes.matches_journey_matchmaker';
const _completed = 'likes.matches_journey_completed';

MatchCard _card({required MatchStage stage, String? formalStatus}) => MatchCard(
  likeRequestId: 42,
  otherUserId: 'other',
  otherUserName: 'نور',
  images: const [],
  stage: stage,
  pendingPhotoExchange: null,
  formalRequest: formalStatus == null
      ? null
      : FormalRequest(
          id: 1,
          maleUserId: 'm',
          maleUserName: 'm',
          femaleUserId: 'f',
          femaleUserName: 'f',
          status: formalStatus,
          statusNameAr: '',
          statusNameEn: '',
          updatedByMatchmakerAt: null,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
  conversationId: null,
);

Future<void> _pump(
  WidgetTester tester,
  MatchCard card, {
  Locale locale = const Locale('ar'),
}) async {
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
          home: Scaffold(body: MatchJourneyCard(card: card)),
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

  // The reason this is a disclosure at all: every card would otherwise stack
  // the same five phrases down the whole list.
  testWidgets('closed, it names the current stage and nothing else', (
    tester,
  ) async {
    await _pump(tester, _card(stage: MatchStage.waitingForPhotoExchange));

    expect(find.text(_likeAccepted), findsOneWidget);
    for (final other in [_liked, _photoExchange, _matchmaker, _completed]) {
      expect(find.text(other), findsNothing, reason: other);
    }
  });

  testWidgets('opened, the whole journey is there', (tester) async {
    await _pump(tester, _card(stage: MatchStage.waitingForPhotoExchange));

    await tester.tap(find.text(_likeAccepted));
    await tester.pumpAndSettle();

    for (final stage in [_liked, _photoExchange, _matchmaker, _completed]) {
      expect(find.text(stage), findsOneWidget, reason: stage);
    }
    // The current one now appears twice: in the summary and in the timeline.
    expect(find.text(_likeAccepted), findsNWidgets(2));
  });

  testWidgets('the summary follows the card it is given', (tester) async {
    await _pump(tester, _card(stage: MatchStage.matchmakerEngaged));
    expect(find.text(_matchmaker), findsOneWidget);

    await _pump(
      tester,
      _card(stage: MatchStage.unknown, formalStatus: 'SuccessfullyClosed'),
    );
    expect(find.text(_completed), findsOneWidget);
  });

  // A closed case reads as "the matchmaker is following up" here, never as a
  // dead end — the business rule reaching the screen.
  testWidgets('a cancelled case still shows a live journey', (tester) async {
    await _pump(
      tester,
      _card(stage: MatchStage.unknown, formalStatus: 'CompatibilityCancelled'),
    );

    expect(find.text(_matchmaker), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('it renders and opens in both directions', (tester) async {
    for (final locale in [const Locale('ar'), const Locale('en')]) {
      // Tear the tree down between locales: the element tree is otherwise
      // reused and the disclosure would carry its open state across.
      await tester.pumpWidget(const SizedBox());
      await _pump(
        tester,
        _card(stage: MatchStage.photosExchanged),
        locale: locale,
      );
      expect(find.text(_matchmaker), findsOneWidget, reason: locale.toString());

      await tester.tap(find.text(_matchmaker));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: locale.toString());
      expect(find.text(_completed), findsOneWidget, reason: locale.toString());
    }
  });
}
