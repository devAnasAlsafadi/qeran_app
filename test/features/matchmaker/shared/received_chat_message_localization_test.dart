import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/enum/message_type.dart';
import 'package:qeran/features/matchmaker/conversations/domain/entities/matchmaker_conversation.dart';
import 'package:qeran/features/matchmaker/shared/data/models/received_chat_message_model.dart';

/// The matchmaker inbox preview. The realtime path CARRIES the localization
/// signal and the card resolves it at build; nothing is localized at merge
/// time, because a cubit has no locale and a frozen row would drift from the
/// thread on a language switch.
MatchmakerConversation _row({
  String? preview,
  MessageType type = MessageType.user,
  String? ar,
  String? en,
}) => MatchmakerConversation(
  userId: 'u-1',
  fullName: 'سارة',
  profileImageUrl: null,
  conversationId: 42,
  lastMessageAt: DateTime.utc(2026, 8, 16),
  lastMessagePreview: preview,
  unreadCount: 0,
  lastMessageType: type,
  lastMessageContentAr: ar,
  lastMessageContentEn: en,
);

void main() {
  group('ReceivedChatMessageModel — carries, never resolves', () {
    test('a system message keeps all three signal fields', () {
      final msg = ReceivedChatMessageModel.fromJson({
        'conversationId': 42,
        'senderId': 'mm-guid',
        'content': 'مرحباً، أنا الخطّابة',
        'type': 'System',
        'contentAr': 'مرحباً، أنا الخطّابة',
        'contentEn': 'Hello, I am your matchmaker',
        'sentAt': '2026-08-16T10:00:00Z',
      });

      expect(msg.type, MessageType.system);
      expect(msg.contentAr, 'مرحباً، أنا الخطّابة');
      expect(msg.contentEn, 'Hello, I am your matchmaker');
      // Raw content is preserved untouched — resolution happens in the card.
      expect(msg.contentPreview, 'مرحباً، أنا الخطّابة');
    });

    test('a user message parses as user with no localized pair', () {
      final msg = ReceivedChatMessageModel.fromJson({
        'conversationId': 42,
        'senderId': 'u-1',
        'content': 'كيف الأحوال؟',
        'type': 'User',
        'sentAt': '2026-08-16T10:00:00Z',
      });

      expect(msg.type, MessageType.user);
      expect(msg.contentAr, isNull);
      expect(msg.contentEn, isNull);
      expect(msg.contentPreview, 'كيف الأحوال؟');
    });

    test('a payload with no type parses as unknown and behaves as user', () {
      // The model mirrors the wire: an absent field is `unknown`, not a
      // guess at `user`. What matters downstream is the BEHAVIOUR — an
      // unknown kind never consults the localized pair, so pre-contract rows
      // preview their plain content rather than blanking.
      final msg = ReceivedChatMessageModel.fromJson({
        'conversationId': 42,
        'senderId': 'u-1',
        'content': 'رسالة قديمة',
        'sentAt': '2026-08-16T10:00:00Z',
      });

      expect(msg.type, MessageType.unknown);
      expect(msg.type.usesLocalizedContent, isFalse);
      expect(msg.contentPreview, 'رسالة قديمة');

      final row = _row(
        preview: msg.contentPreview,
        type: msg.type,
        en: 'must not be used',
      );
      expect(row.previewText(isArabic: false), 'رسالة قديمة');
    });
  });

  group('MatchmakerConversation.previewText', () {
    test('a system row picks the active locale', () {
      final row = _row(
        preview: 'مرحباً',
        type: MessageType.system,
        ar: 'مرحباً',
        en: 'Hello',
      );
      expect(row.previewText(isArabic: true), 'مرحباً');
      expect(row.previewText(isArabic: false), 'Hello');
    });

    test('a user row ignores the pair entirely', () {
      final row = _row(
        preview: 'كيف الأحوال؟',
        ar: 'never',
        en: 'never',
      );
      expect(row.previewText(isArabic: false), 'كيف الأحوال؟');
    });

    test('a REST row with no signal falls back to the server preview', () {
      // This is the documented gap: the backend rendered the string and the
      // client cannot re-language it until Tariq ships Ar/En variants.
      final row = _row(preview: 'مرحباً، أنا الخطّابة');
      expect(row.previewText(isArabic: false), 'مرحباً، أنا الخطّابة');
    });

    test('an empty or missing localized field falls back to the preview', () {
      final blank = _row(
        preview: 'fallback',
        type: MessageType.system,
        ar: 'مرحباً',
        en: '',
      );
      expect(blank.previewText(isArabic: false), 'fallback');

      final absent = _row(
        preview: 'fallback',
        type: MessageType.system,
        ar: 'مرحباً',
      );
      expect(absent.previewText(isArabic: false), 'fallback');
    });

    test('a null preview with no signal reads as empty, never null', () {
      expect(_row().previewText(isArabic: true), isEmpty);
    });
  });

  group('withLastMessage — the live update', () {
    test('a system message arriving live localizes the row', () {
      final before = _row(preview: 'كيف الأحوال؟');
      expect(before.previewText(isArabic: false), 'كيف الأحوال؟');

      final after = before.withLastMessage(
        preview: 'مرحباً',
        at: DateTime.utc(2026, 8, 16, 11),
        unreadCount: 1,
        type: MessageType.system,
        contentAr: 'مرحباً',
        contentEn: 'Hello',
      );

      expect(after.previewText(isArabic: false), 'Hello');
      expect(after.previewText(isArabic: true), 'مرحباً');
      expect(after.unreadCount, 1);
    });

    test('the localization tuple is REPLACED, never merged', () {
      // The bug this guards: a per-field `??` carry-over would leave the old
      // English rendition in place, so an EN reader would keep seeing the
      // PREVIOUS message's text under a newer Arabic-only one.
      final stale = _row(
        preview: 'old',
        type: MessageType.system,
        ar: 'قديم',
        en: 'Old english',
      );

      final fresh = stale.withLastMessage(
        preview: 'جديد',
        at: DateTime.utc(2026, 8, 16, 12),
        unreadCount: 0,
        type: MessageType.system,
        contentAr: 'جديد',
        contentEn: null,
      );

      expect(fresh.lastMessageContentEn, isNull);
      expect(fresh.previewText(isArabic: false), 'جديد');
    });

    test('a user message after a system one drops the stale pair', () {
      final system = _row(
        preview: 'مرحباً',
        type: MessageType.system,
        ar: 'مرحباً',
        en: 'Hello',
      );

      final user = system.withLastMessage(
        preview: 'كيف الأحوال؟',
        at: DateTime.utc(2026, 8, 16, 13),
        unreadCount: 0,
        type: MessageType.user,
        contentAr: null,
        contentEn: null,
      );

      expect(user.previewText(isArabic: false), 'كيف الأحوال؟');
      expect(user.lastMessageContentEn, isNull);
    });

    test('copyWith carries the tuple through an unread-only update', () {
      // `markConversationRead` uses copyWith; it must not blank a localized
      // row as a side effect of clearing the badge.
      final row = _row(
        preview: 'مرحباً',
        type: MessageType.system,
        ar: 'مرحباً',
        en: 'Hello',
      ).copyWith(unreadCount: 0);

      expect(row.previewText(isArabic: false), 'Hello');
    });
  });
}
