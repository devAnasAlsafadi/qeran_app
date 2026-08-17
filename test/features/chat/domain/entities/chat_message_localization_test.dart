import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/enum/message_type.dart';
import 'package:qeran/features/chat/domain/entities/chat_message.dart';
import 'package:qeran/features/chat/domain/entities/message_send_status.dart';

/// `content` is deliberately a DISTINCT sentinel from `contentAr` in most of
/// these cases. In production they are usually the same Arabic string, which
/// would make "fell back to content" and "reached for the other language"
/// indistinguishable — the exact confusion decision #2 rules out.
ChatMessage _msg({
  String content = 'THE-FALLBACK',
  MessageType type = MessageType.user,
  String? ar,
  String? en,
  int? serverId = 1,
  String? clientTempId,
  MessageSendStatus status = MessageSendStatus.sent,
}) => ChatMessage(
  serverId: serverId,
  clientTempId: clientTempId,
  conversationId: 42,
  senderId: 'mm-guid',
  senderName: 'سلمى',
  content: content,
  type: type,
  contentAr: ar,
  contentEn: en,
  sharedProfile: null,
  isRead: false,
  sentAt: DateTime.utc(2026, 8, 16),
  status: status,
);

void main() {
  group('ChatMessage.displayText', () {
    test('a system message picks the active locale', () {
      final msg = _msg(
        type: MessageType.system,
        ar: 'مرحباً، أنا الخطّابة',
        en: 'Hello, I am your matchmaker',
      );

      expect(msg.displayText(isArabic: true), 'مرحباً، أنا الخطّابة');
      expect(msg.displayText(isArabic: false), 'Hello, I am your matchmaker');
    });

    test('a user message ignores the pair entirely', () {
      // A user message should never carry a pair, but if the backend ever
      // sent one it must not override what the person actually typed.
      final msg = _msg(content: 'كيف الأحوال؟', ar: 'never', en: 'never');

      expect(msg.displayText(isArabic: true), 'كيف الأحوال؟');
      expect(msg.displayText(isArabic: false), 'كيف الأحوال؟');
    });

    test('an unknown kind renders as plain text, never blank', () {
      // Pre-contract rows parse as `unknown`. The failure this guards is an
      // empty bubble, which is worse than the wrong language.
      final msg = _msg(
        content: 'رسالة قديمة',
        type: MessageType.unknown,
        en: 'must not be used',
      );

      expect(msg.displayText(isArabic: false), 'رسالة قديمة');
    });

    test('the hand-built default is user — the optimistic temp', () {
      // The only entity constructed by hand is the outgoing temp, which the
      // user did author. Defaulting it to `unknown` would be a lie about a
      // message whose kind we know for certain.
      final temp = _msg(
        content: 'مرحبا',
        serverId: null,
        clientTempId: 'tmp-1',
        status: MessageSendStatus.sending,
      );

      expect(temp.type, MessageType.user);
      expect(temp.displayText(isArabic: false), 'مرحبا');
    });

    test('a missing rendition falls back to content, NOT the other language',
        () {
      // Decision #2: no opposite-language attempt. An EN reader on an
      // Arabic-only system message gets `content` — which is the Arabic the
      // backend always sends — reached by the fallback rule, not by a
      // deliberate "try contentAr" branch.
      final arOnly = _msg(
        type: MessageType.system,
        ar: 'النص العربي',
        en: null,
      );

      expect(arOnly.displayText(isArabic: false), 'THE-FALLBACK');
      expect(arOnly.displayText(isArabic: false), isNot('النص العربي'));
    });

    test('a blank rendition is treated exactly like a missing one', () {
      // `parseNullableString` keeps `""` as an empty string rather than
      // nulling it, so the resolver — not the model — has to collapse the
      // two. An empty bubble would otherwise ship.
      final blank = _msg(type: MessageType.system, ar: 'النص', en: '');

      expect(blank.displayText(isArabic: false), 'THE-FALLBACK');
    });

    test('an English-only system message localizes EN and falls back for AR',
        () {
      // The pair is not assumed symmetric; each side is checked on its own.
      final enOnly = _msg(
        type: MessageType.system,
        ar: null,
        en: 'English only',
      );

      expect(enOnly.displayText(isArabic: false), 'English only');
      expect(enOnly.displayText(isArabic: true), 'THE-FALLBACK');
    });
  });

  group('copyWith carries the localization triple', () {
    test('reconciling an optimistic temp keeps it', () {
      // `ChatMessage`'s constructor names every field, so an omission in
      // copyWith silently resets a message to the defaults. This is the path
      // that would do it: temp → server id + sent.
      final system = _msg(
        type: MessageType.system,
        ar: 'مرحباً',
        en: 'Hello',
        serverId: null,
        clientTempId: 'tmp-1',
        status: MessageSendStatus.sending,
      );

      final reconciled = system.copyWith(
        serverId: 105,
        status: MessageSendStatus.sent,
      );

      expect(reconciled.type, MessageType.system);
      expect(reconciled.displayText(isArabic: false), 'Hello');
    });

    test('marking read keeps it', () {
      final read = _msg(
        type: MessageType.system,
        ar: 'مرحباً',
        en: 'Hello',
      ).copyWith(isRead: true);

      expect(read.isRead, isTrue);
      expect(read.displayText(isArabic: false), 'Hello');
    });
  });

  group('equality', () {
    test('two messages differing only in rendition are not equal', () {
      // The triple is in `props`, so a live edit or a re-fetch that changes
      // only the localized text still repaints the list.
      final a = _msg(type: MessageType.system, ar: 'مرحباً', en: 'Hello');
      final b = _msg(type: MessageType.system, ar: 'مرحباً', en: 'Hi there');

      expect(a, isNot(b));
    });
  });
}
