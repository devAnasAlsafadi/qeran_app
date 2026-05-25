import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/chat/data/models/messages_read_event_model.dart';

void main() {
  group('MessagesReadEventModel — parsing', () {
    test('full payload parses', () {
      final entity = MessagesReadEventModel.fromJson({
        'conversationId': 42,
        'readByUserId': 'guid',
        'readAt': '2026-05-17T15:30:00Z',
      }).toEntity();
      expect(entity.conversationId, 42);
      expect(entity.readByUserId, 'guid');
      expect(entity.readAt.year, 2026);
    });

    test('conversationId arrives as numeric string', () {
      final entity = MessagesReadEventModel.fromJson({
        'conversationId': '42',
        'readByUserId': 'guid',
        'readAt': '2026-05-17T15:30:00Z',
      }).toEntity();
      expect(entity.conversationId, 42);
    });

    test('missing readAt defaults to now', () {
      final before = DateTime.now().toUtc();
      final entity = MessagesReadEventModel.fromJson({
        'conversationId': 42,
        'readByUserId': 'guid',
      }).toEntity();
      // Defensive: never throw, never null.
      expect(entity.readAt.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
    });
  });
}
