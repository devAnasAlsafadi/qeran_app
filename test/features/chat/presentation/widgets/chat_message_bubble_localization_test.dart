import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/enum/message_type.dart';
import 'package:qeran/features/chat/domain/entities/chat_message.dart';
import 'package:qeran/features/chat/domain/entities/message_send_status.dart';
import 'package:qeran/features/chat/domain/entities/shared_profile.dart';
import 'package:qeran/features/chat/presentation/widgets/chat_message_bubble.dart';
import 'package:qeran/features/chat/presentation/widgets/shared_profile_message_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Decision #1: switching language with the thread OPEN has to update every
/// system bubble immediately — no pull-to-refresh, no refetch, no remount.
///
/// The thread is a pushed route, so it sits OUTSIDE the `LocaleRebuildScope`
/// that discards the home tabs on a switch. Nothing else would repaint it:
/// resolving inside `build` from `context.locale` is the entire mechanism,
/// which is why these tests assert the Element survives the switch.

const _ar = 'مرحباً، أنا الخطّابة';
const _en = 'Hello, I am your matchmaker';
const _fallback = 'THE-FALLBACK';

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    return const {
      'chat': {
        'message_read_label': 'Read',
        'send_failed_retry': 'Retry',
        'shared_profile_score_label': 'Compatibility {percent}%',
        'shared_profile_shared_by_matchmaker': 'Shared by {name}',
        'shared_profile_shared_by_me': 'You shared this profile',
        'shared_profile_view_cta': 'View profile',
      }
    };
  }
}

ChatMessage _msg({
  String content = _fallback,
  MessageType type = MessageType.system,
  String? ar = _ar,
  String? en = _en,
  SharedProfile? sharedProfile,
}) => ChatMessage(
  serverId: 105,
  clientTempId: null,
  conversationId: 42,
  senderId: 'mm-guid',
  senderName: 'سلمى',
  content: content,
  type: type,
  contentAr: ar,
  contentEn: en,
  sharedProfile: sharedProfile,
  isRead: false,
  sentAt: DateTime.utc(2026, 8, 16, 10),
  status: MessageSendStatus.sent,
);

Future<void> _pump(WidgetTester tester, ChatMessage message) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      startLocale: const Locale('en'),
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: ChatMessageBubble(
              message: message,
              isMine: false,
              showReadReceipt: false,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _switchTo(WidgetTester tester, String code) async {
  final ctx = tester.element(find.byType(MaterialApp));
  await ctx.setLocale(Locale(code));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('a system bubble flips language in place, with no refresh',
      (tester) async {
    await _pump(tester, _msg());
    expect(find.text(_en), findsOneWidget);
    expect(find.text(_ar), findsNothing);

    final before = tester.element(find.byType(ChatMessageBubble));

    await _switchTo(tester, 'ar');
    expect(find.text(_ar), findsOneWidget);
    expect(find.text(_en), findsNothing);

    // The same Element — the bubble was REPAINTED, not remounted. A remount
    // would mean the thread had been discarded and refetched, which is the
    // behaviour decision #1 rules out.
    expect(
      identical(before, tester.element(find.byType(ChatMessageBubble))),
      isTrue,
    );
  });

  testWidgets('and flips back', (tester) async {
    await _pump(tester, _msg());
    await _switchTo(tester, 'ar');
    await _switchTo(tester, 'en');

    expect(find.text(_en), findsOneWidget);
    expect(find.text(_ar), findsNothing);
  });

  testWidgets('a user bubble is untouched by the switch', (tester) async {
    await _pump(tester, _msg(
      content: 'كيف الأحوال؟',
      type: MessageType.user,
      ar: 'never',
      en: 'never',
    ));
    expect(find.text('كيف الأحوال؟'), findsOneWidget);

    await _switchTo(tester, 'ar');

    expect(find.text('كيف الأحوال؟'), findsOneWidget);
    expect(find.text('never'), findsNothing);
  });

  testWidgets('a pre-contract bubble renders its plain content in both locales',
      (tester) async {
    await _pump(tester, _msg(
      content: 'رسالة قديمة',
      type: MessageType.unknown,
      ar: null,
      en: null,
    ));
    expect(find.text('رسالة قديمة'), findsOneWidget);

    await _switchTo(tester, 'ar');

    // Never blank — an empty bubble is worse than the wrong language.
    expect(find.text('رسالة قديمة'), findsOneWidget);
  });

  testWidgets('a one-language system bubble falls back rather than blanking',
      (tester) async {
    await _pump(tester, _msg(ar: _ar, en: null));

    expect(find.text(_fallback), findsOneWidget);
    expect(find.text(_ar), findsNothing,
        reason: 'no opposite-language attempt — decision #2');

    await _switchTo(tester, 'ar');
    expect(find.text(_ar), findsOneWidget);
  });

  testWidgets('the shared-profile branch never reaches the resolver',
      (tester) async {
    // Sentinels on a shared-profile message: if the localization path could
    // ever leak into this branch, one of them would render.
    await _pump(tester, _msg(
      content: '[profile:guid-x]',
      ar: 'AR-LEAK',
      en: 'EN-LEAK',
      sharedProfile: const SharedProfile(
        id: 'guid-x',
        name: 'نور',
        age: 27,
        matchingScore: 0,
        images: [],
      ),
    ));

    expect(find.byType(SharedProfileMessageCard), findsOneWidget);
    expect(find.text('EN-LEAK'), findsNothing);
    expect(find.text('AR-LEAK'), findsNothing);
    expect(find.textContaining('[profile:'), findsNothing);

    await _switchTo(tester, 'ar');

    expect(find.byType(SharedProfileMessageCard), findsOneWidget);
    expect(find.text('AR-LEAK'), findsNothing);
    expect(find.textContaining('[profile:'), findsNothing);
  });
}
