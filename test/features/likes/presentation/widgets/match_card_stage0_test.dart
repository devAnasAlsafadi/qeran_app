import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_direction.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_pending.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_status.dart';
import 'package:qeran/features/likes/presentation/widgets/match_card_stage0.dart';
import 'package:qeran/features/likes/presentation/widgets/photo_exchange_action_row.dart';
import 'package:qeran/features/likes/presentation/widgets/photo_exchange_countdown_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Returns no translations — `context.tr(key)` falls back to the key
/// string, which is enough for these tests (they assert on widget
/// presence, not user-visible copy).
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

MatchCard _card({required PhotoExchangePending? pending}) {
  return MatchCard(
    likeRequestId: 42,
    otherUserId: 'guid-other',
    otherUserName: 'نور',
    images: const [],
    stage: MatchStage.waitingForPhotoExchange,
    pendingPhotoExchange: pending,
    formalRequest: null,
    conversationId: null,
  );
}

PhotoExchangePending _pending({
  required PhotoExchangeDirection direction,
  required bool requestedByMe,
  required bool canAccept,
  required bool canReject,
}) {
  return PhotoExchangePending(
    id: 7,
    likeRequestId: 42,
    initiatorId: 'i',
    responderId: 'r',
    status: PhotoExchangeStatus.pending,
    statusCode: 0,
    remainingSeconds: 3600,
    createdAt: DateTime.utc(2026),
    expiresAt: DateTime.utc(2026, 5, 22),
    direction: direction,
    requestedByMe: requestedByMe,
    canAccept: canAccept,
    canReject: canReject,
  );
}

Future<void> _pump(WidgetTester tester, MatchCard card) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: MatchCardStage0(
              card: card,
              onRequestPhotoExchange: () {},
              isRequestingPhotoExchange: false,
              onAcceptPhotoExchange: () {},
              onRejectPhotoExchange: () {},
              isAcceptingPhotoExchange: false,
              isRejectingPhotoExchange: false,
              onPendingExpiredLocally: null,
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

  testWidgets(
      'pendingPhotoExchange == null → request CTA (no action row, no chip)',
      (tester) async {
    await _pump(tester, _card(pending: null));
    expect(find.byType(PhotoExchangeActionRow), findsNothing);
    expect(find.byType(PhotoExchangeCountdownChip), findsNothing);
  });

  testWidgets(
      'Receiver (canAccept && canReject, requestedByMe=false) → '
      'shows Accept/Reject buttons (the real Ali-bug scenario)',
      (tester) async {
    final card = _card(
      pending: _pending(
        direction: PhotoExchangeDirection.received,
        requestedByMe: false,
        canAccept: true,
        canReject: true,
      ),
    );
    await _pump(tester, card);
    expect(find.byType(PhotoExchangeActionRow), findsOneWidget);
    expect(find.byType(PhotoExchangeCountdownChip), findsOneWidget);
  });

  testWidgets(
      'Initiator (requestedByMe=true) → waiting state, NO action row',
      (tester) async {
    final card = _card(
      pending: _pending(
        direction: PhotoExchangeDirection.sent,
        requestedByMe: true,
        canAccept: false,
        canReject: false,
      ),
    );
    await _pump(tester, card);
    expect(find.byType(PhotoExchangeActionRow), findsNothing);
    expect(find.byType(PhotoExchangeCountdownChip), findsOneWidget);
  });

  testWidgets(
      'Defensive: Received but neither flag → waiting state '
      '(no buttons, just countdown)', (tester) async {
    // Window closed for the receiver, refresh will move it off Stage 0.
    final card = _card(
      pending: _pending(
        direction: PhotoExchangeDirection.received,
        requestedByMe: false,
        canAccept: false,
        canReject: false,
      ),
    );
    await _pump(tester, card);
    expect(find.byType(PhotoExchangeActionRow), findsNothing);
    expect(find.byType(PhotoExchangeCountdownChip), findsOneWidget);
  });

  testWidgets(
      'Edge case: only canAccept=true → still enters the buttons branch',
      (tester) async {
    final card = _card(
      pending: _pending(
        direction: PhotoExchangeDirection.received,
        requestedByMe: false,
        canAccept: true,
        canReject: false,
      ),
    );
    await _pump(tester, card);
    expect(find.byType(PhotoExchangeActionRow), findsOneWidget);
  });
}
