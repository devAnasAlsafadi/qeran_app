// easy_localization re-exports intl, whose TextDirection collides with
// dart:ui's — the one Directionality actually takes.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/server_clock.dart';
import 'package:qeran/features/likes/presentation/widgets/like_card_countdown_chip.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/data/models/case_photo_exchange_model.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_chat.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_photo_exchange.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_photo_exchange_status.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/case_user.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/compatibility_case_stage.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/widgets/matchmaker_case_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The case card shows a live photo-exchange countdown, and ONLY while the
/// request is genuinely open. `photoExchange.expiresAt` now comes back on
/// lapsed requests too, so presence of the field cannot be the gate.

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

CompatibilityCase _case({CasePhotoExchange? exchange}) {
  const user = CaseUser(
    userId: 'u',
    name: 'A',
    profileImageUrl: null,
    age: null,
    gender: null,
    isAssignedToMe: true,
  );
  return CompatibilityCase(
    caseId: 1,
    myUser: user,
    otherUser: user,
    likeAcceptedAt: null,
    stage: CompatibilityCaseStage.photoExchangePending,
    photoExchange: exchange,
    formalRequest: null,
    chat: const CaseChat(
      myUserConversationId: null,
      otherUserConversationId: null,
      otherMatchmakerId: null,
      otherMatchmakerConversationId: null,
      otherMatchmakerName: null,
      otherMatchmakerImageUrl: null,
    ),
    canUpdateFormalRequestStatus: true,
    hasMyNote: false,
  );
}

CasePhotoExchange _exchange({
  CasePhotoExchangeStatus status = CasePhotoExchangeStatus.pending,
  DateTime? expiresAt,
}) => CasePhotoExchange(
  requestId: 42,
  status: status,
  respondedAt: null,
  initiatorId: null,
  responderId: null,
  expiresAt: expiresAt,
);

Future<void> _pump(WidgetTester tester, CompatibilityCase item) async {
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
          home: Scaffold(
            body: SingleChildScrollView(
              child: MatchmakerCaseCard(caseItem: item),
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

  setUp(ServerClock.resetForTest);

  group('the countdown on a case card', () {
    testWidgets('shows while the request is still open', (tester) async {
      await _pump(
        tester,
        _case(
          exchange: _exchange(
            expiresAt: DateTime.now().toUtc().add(const Duration(hours: 5)),
          ),
        ),
      );

      expect(find.byType(LikeCountdownChip), findsOneWidget);
    });

    testWidgets('hides once the deadline has passed', (tester) async {
      // Still "Pending" — the server has not swept it yet. This is the case
      // the old presence-based gate got wrong.
      await _pump(
        tester,
        _case(
          exchange: _exchange(
            expiresAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 1),
            ),
          ),
        ),
      );

      expect(find.byType(LikeCountdownChip), findsNothing);
    });

    testWidgets('hides for a resolved request with a future deadline', (
      tester,
    ) async {
      await _pump(
        tester,
        _case(
          exchange: _exchange(
            status: CasePhotoExchangeStatus.accepted,
            expiresAt: DateTime.now().toUtc().add(const Duration(hours: 5)),
          ),
        ),
      );

      expect(find.byType(LikeCountdownChip), findsNothing);
    });

    testWidgets('renders fine with no photoExchange block at all', (
      tester,
    ) async {
      // Backward compatibility: older payloads and cached rows have none.
      await _pump(tester, _case());

      expect(find.byType(LikeCountdownChip), findsNothing);
      expect(find.byType(MatchmakerCaseCard), findsOneWidget);
    });

    testWidgets('renders fine when the block predates expiresAt', (
      tester,
    ) async {
      await _pump(tester, _case(exchange: _exchange()));

      // Nothing to count down to — but no crash, and the card still draws.
      expect(find.byType(LikeCountdownChip), findsNothing);
      expect(find.byType(MatchmakerCaseCard), findsOneWidget);
    });
  });

  group('parsing the new field', () {
    test('reads expiresAt off the wire', () {
      final model = CasePhotoExchangeModel.fromJson(const {
        'requestId': 42,
        'status': 'Pending',
        'expiresAt': '2026-08-14T09:30:00Z',
      });

      expect(model.expiresAt, isNotNull);
      expect(model.toEntity().expiresAt, model.expiresAt);
      expect(model.toEntity().status, CasePhotoExchangeStatus.pending);
    });

    test('an older payload without the field parses to null, not a throw', () {
      final entity = CasePhotoExchangeModel.fromJson(const {
        'requestId': 42,
        'status': 'Pending',
      }).toEntity();

      expect(entity.expiresAt, isNull);
      // And "no deadline" must not read as "expired".
      expect(entity.isAwaitingResponse, isTrue);
    });
  });
}
