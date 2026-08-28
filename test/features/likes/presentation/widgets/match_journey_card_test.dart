import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/formal_request.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
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

const _initial = 'likes.matches_journey_initial_compatibility';
const _photoExchange = 'likes.matches_journey_photo_exchange';
const _formalContact = 'likes.matches_journey_formal_contact';
const _formalMeeting = 'likes.matches_journey_formal_meeting';
const _marriage = 'likes.matches_journey_marriage_completed';
const _ended = 'likes.matches_journey_ended';

/// The four a card is NOT standing on when it stands on [current].
List<String> _others(String current) =>
    [_initial, _photoExchange, _formalContact, _formalMeeting, _marriage]
        .where((k) => k != current)
        .toList();

MatchCard _card({
  MatchCaseStage caseStage = MatchCaseStage.unknown,
  MatchStage stage = MatchStage.unknown,
  String? formalStatus,
}) => MatchCard(
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
  caseStage: caseStage,
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
    await _pump(tester, _card(caseStage: MatchCaseStage.likeAccepted));

    expect(find.text(_initial), findsOneWidget);
    for (final other in _others(_initial)) {
      expect(find.text(other), findsNothing, reason: other);
    }
  });

  testWidgets('opened, the whole journey is there', (tester) async {
    await _pump(tester, _card(caseStage: MatchCaseStage.likeAccepted));

    await tester.tap(find.text(_initial));
    await tester.pumpAndSettle();

    for (final stage in _others(_initial)) {
      expect(find.text(stage), findsOneWidget, reason: stage);
    }
    // The current one now appears twice: in the summary and in the timeline.
    expect(find.text(_initial), findsNWidgets(2));
  });

  testWidgets('the summary follows the card it is given', (tester) async {
    await _pump(tester, _card(caseStage: MatchCaseStage.formalStepPending));
    expect(find.text(_formalContact), findsOneWidget);

    await _pump(tester, _card(caseStage: MatchCaseStage.marriageCompleted));
    expect(find.text(_marriage), findsOneWidget);
  });

  // The reversal reaching the screen, and through the legacy fallback at that:
  // a row this old carries no readable caseStage, so the ending has to be read
  // off `formalRequest`. It used to assert the exact opposite — that a
  // cancelled case still drew as a live formal step — which was the old
  // blanket rule, correct for a declined photo exchange and wrong here.
  //
  // The row is CLOSED. That is the whole point: an ending carried only by the
  // timeline inside would leave a stopped case looking live until someone
  // tapped it.
  testWidgets('a cancelled case reads as ended without being opened', (
    tester,
  ) async {
    await _pump(
      tester,
      _card(stage: MatchStage.unknown, formalStatus: 'CompatibilityCancelled'),
    );

    expect(find.text(_ended), findsOneWidget);
    expect(find.text(_formalContact), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
  });

  // The neutral label replaces the node's own name rather than sitting beside
  // it, and only on the node the member stands on. Cancelling does not move
  // the stage, so without the override a case ended at the photo step would
  // read «تبادل الصور» under a danger cross — naming the wrong event with
  // full confidence.
  testWidgets('the ended node drops its stage name, and only it does', (
    tester,
  ) async {
    await _pump(
      tester,
      _card(stage: MatchStage.unknown, formalStatus: 'CompatibilityCancelled'),
    );

    await tester.tap(find.text(_ended));
    await tester.pumpAndSettle();

    // Summary and timeline node, both reporting the ending.
    expect(find.text(_ended), findsNWidgets(2));
    expect(find.text(_formalContact), findsNothing);
    for (final other in const [_initial, _photoExchange, _formalMeeting, _marriage]) {
      expect(find.text(other), findsOneWidget, reason: other);
    }
  });

  // A running case is untouched by any of it: gold glyph, canonical name, no
  // danger anywhere.
  testWidgets('a running case keeps its stage name and its gold glyph', (
    tester,
  ) async {
    await _pump(tester, _card(caseStage: MatchCaseStage.formalStepPending));

    expect(find.text(_formalContact), findsOneWidget);
    expect(find.text(_ended), findsNothing);
    expect(find.byIcon(Icons.timeline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
  });

  testWidgets('it renders and opens in both directions', (tester) async {
    for (final locale in [const Locale('ar'), const Locale('en')]) {
      // Tear the tree down between locales: the element tree is otherwise
      // reused and the disclosure would carry its open state across.
      await tester.pumpWidget(const SizedBox());
      await _pump(
        tester,
        _card(caseStage: MatchCaseStage.parentsVisited),
        locale: locale,
      );
      expect(
        find.text(_formalMeeting),
        findsOneWidget,
        reason: locale.toString(),
      );

      await tester.tap(find.text(_formalMeeting));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: locale.toString());
      expect(find.text(_marriage), findsOneWidget, reason: locale.toString());
    }
  });

  // The row sits under a big gold CTA and looks like the status line above it,
  // so the chevron alone was read as decoration. The hint says outright that
  // something is behind the row, then retires once the member has opened one.
  testWidgets('closed, it says what opening the row reveals', (tester) async {
    await _pump(tester, _card(caseStage: MatchCaseStage.likeAccepted));

    expect(find.textContaining('likes.matches_journey_view'), findsOneWidget);
  });

  testWidgets('the hint retires once the journey is open', (tester) async {
    await _pump(tester, _card(caseStage: MatchCaseStage.likeAccepted));

    await tester.tap(find.text(_initial));
    await tester.pumpAndSettle();

    expect(find.textContaining('likes.matches_journey_view'), findsNothing);
  });
}
