// easy_localization re-exports intl, whose TextDirection collides with
// dart:ui's — the one Directionality actually takes.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/server_clock.dart';
import 'package:qeran/features/likes/presentation/widgets/like_card_countdown_chip.dart';
import 'package:qeran/features/matchmaker/interests/data/models/matchmaker_interest_match_model.dart';
import 'package:qeran/features/matchmaker/interests/domain/entities/matchmaker_interest_enums.dart';
import 'package:qeran/features/matchmaker/interests/domain/entities/matchmaker_interest_like.dart';
import 'package:qeran/features/matchmaker/interests/domain/entities/matchmaker_interest_match.dart';
import 'package:qeran/features/matchmaker/interests/domain/entities/matchmaker_interest_photo_exchange.dart';
import 'package:qeran/features/matchmaker/interests/presentation/widgets/matchmaker_interest_like_card.dart';
import 'package:qeran/features/matchmaker/interests/presentation/widgets/matchmaker_interest_match_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The matchmaker interests screen has three tabs and two card widgets: the
/// two like tabs share [MatchmakerInterestLikeCard], the active-compatibility
/// tab has [MatchmakerInterestMatchCard]. A deadline must read the same on
/// both, or one screen tells two stories about the same clock.

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

final _future = DateTime.now().toUtc().add(const Duration(hours: 5));
final _past = DateTime.now().toUtc().subtract(const Duration(minutes: 3));

MatchmakerInterestLike _like({
  required MatchmakerInterestLikeStatus status,
  DateTime? expiresAt,
}) => MatchmakerInterestLike(
  otherUserId: 'u',
  name: 'enas',
  image: null,
  status: status,
  isLocked: false,
  expiresAt: expiresAt,
);

MatchmakerInterestMatch _match({MatchmakerInterestPhotoExchange? exchange}) =>
    MatchmakerInterestMatch(
      otherUserId: 'u',
      name: 'enas',
      stage: MatchmakerInterestMatchStage.waitingForPhotoExchange,
      pendingPhotoExchange: exchange,
    );

MatchmakerInterestPhotoExchange _exchange({
  MatchmakerInterestPhotoExchangeStatus status =
      MatchmakerInterestPhotoExchangeStatus.pending,
  DateTime? expiresAt,
}) => MatchmakerInterestPhotoExchange(status: status, expiresAt: expiresAt);

Future<void> _pump(WidgetTester tester, Widget card) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Scaffold(body: SingleChildScrollView(child: card)),
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

  setUp(ServerClock.resetForTest);

  group('the two like tabs', () {
    testWidgets('a live pending like counts down', (tester) async {
      await _pump(
        tester,
        MatchmakerInterestLikeCard(
          like: _like(
            status: MatchmakerInterestLikeStatus.pending,
            expiresAt: _future,
          ),
        ),
      );

      expect(find.byType(LikeCountdownChip), findsOneWidget);
    });

    testWidgets('a lapsed one does not, though it is still Pending', (
      tester,
    ) async {
      await _pump(
        tester,
        MatchmakerInterestLikeCard(
          like: _like(
            status: MatchmakerInterestLikeStatus.pending,
            expiresAt: _past,
          ),
        ),
      );

      expect(find.byType(LikeCountdownChip), findsNothing);
    });

    testWidgets('an accepted row keeps its label and loses the clock', (
      tester,
    ) async {
      // The archive rows the matchmaker actually sees: مقبول / منتهي.
      await _pump(
        tester,
        MatchmakerInterestLikeCard(
          like: _like(
            status: MatchmakerInterestLikeStatus.accepted,
            expiresAt: _future,
          ),
        ),
      );

      expect(find.byType(LikeCountdownChip), findsNothing);
    });
  });

  group('the active-compatibility tab', () {
    testWidgets('a running photo exchange counts down', (tester) async {
      await _pump(
        tester,
        MatchmakerInterestMatchCard(
          match: _match(exchange: _exchange(expiresAt: _future)),
        ),
      );

      expect(find.byType(LikeCountdownChip), findsOneWidget);
    });

    testWidgets('a lapsed exchange does not', (tester) async {
      await _pump(
        tester,
        MatchmakerInterestMatchCard(
          match: _match(exchange: _exchange(expiresAt: _past)),
        ),
      );

      expect(find.byType(LikeCountdownChip), findsNothing);
    });

    testWidgets('a resolved exchange does not, future deadline or not', (
      tester,
    ) async {
      for (final status in [
        MatchmakerInterestPhotoExchangeStatus.accepted,
        MatchmakerInterestPhotoExchangeStatus.rejected,
        MatchmakerInterestPhotoExchangeStatus.expired,
      ]) {
        await _pump(
          tester,
          MatchmakerInterestMatchCard(
            match: _match(
              exchange: _exchange(status: status, expiresAt: _future),
            ),
          ),
        );

        expect(find.byType(LikeCountdownChip), findsNothing, reason: '$status');
      }
    });

    testWidgets('a match with no exchange at all still renders', (
      tester,
    ) async {
      await _pump(tester, MatchmakerInterestMatchCard(match: _match()));

      expect(find.byType(LikeCountdownChip), findsNothing);
      expect(find.byType(MatchmakerInterestMatchCard), findsOneWidget);
    });
  });

  group('parsing pendingPhotoExchange off the match DTO', () {
    test('reads status and deadline, both wire shapes of status', () {
      for (final raw in <Object>['Pending', 0]) {
        final entity = MatchmakerInterestMatchModel.fromJson({
          'otherUserId': 'u',
          'otherUserName': 'enas',
          'stage': 0,
          'pendingPhotoExchange': {
            'status': raw,
            'expiresAt': '2026-08-14T09:30:00Z',
            'remainingSeconds': 600,
          },
        }).toEntity();

        expect(
          entity.pendingPhotoExchange?.status,
          MatchmakerInterestPhotoExchangeStatus.pending,
          reason: 'status as $raw',
        );
        expect(entity.pendingPhotoExchange?.expiresAt, isNotNull);
        expect(entity.pendingPhotoExchange?.remainingSeconds, 600);
      }
    });

    test('no block → null, and the card has nothing to show', () {
      final entity = MatchmakerInterestMatchModel.fromJson({
        'otherUserId': 'u',
        'otherUserName': 'enas',
        'stage': 0,
      }).toEntity();

      expect(entity.pendingPhotoExchange, isNull);
    });

    test('a block without expiresAt is not treated as expired', () {
      // Rollout: the deadline is newer than the DTO. Absent means "nothing to
      // count", and the request is still considered open.
      final entity = MatchmakerInterestMatchModel.fromJson({
        'otherUserId': 'u',
        'otherUserName': 'enas',
        'stage': 0,
        'pendingPhotoExchange': {'status': 'Pending'},
      }).toEntity();

      expect(entity.pendingPhotoExchange?.expiresAt, isNull);
      expect(entity.pendingPhotoExchange?.isAwaitingResponse, isTrue);
    });
  });
}
