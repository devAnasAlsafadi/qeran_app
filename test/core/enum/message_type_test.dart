import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/enum/message_type.dart';

/// The wire sends PascalCase (`User` / `System`). Parsing must survive that,
/// survive the field being absent entirely, and never throw — an unrecognised
/// kind has to render as ordinary text rather than blank the bubble.
void main() {
  group('MessageType.fromWire', () {
    test('parses the wire values as sent', () {
      expect(MessageType.fromWire('User'), MessageType.user);
      expect(MessageType.fromWire('System'), MessageType.system);
    });

    test('is case-insensitive', () {
      // The enum serialization is capital-first today; a lower-case or
      // shouty variant must not silently become `unknown`.
      for (final raw in ['user', 'USER', 'UsEr']) {
        expect(MessageType.fromWire(raw), MessageType.user, reason: raw);
      }
      for (final raw in ['system', 'SYSTEM', 'SyStEm']) {
        expect(MessageType.fromWire(raw), MessageType.system, reason: raw);
      }
    });

    test('a missing or blank type is unknown, not a guess', () {
      expect(MessageType.fromWire(null), MessageType.unknown);
      expect(MessageType.fromWire(''), MessageType.unknown);
      expect(MessageType.fromWire('   '), MessageType.unknown);
    });

    test('an unrecognised future kind degrades to unknown', () {
      expect(MessageType.fromWire('Announcement'), MessageType.unknown);
      expect(MessageType.fromWire('Bot'), MessageType.unknown);
    });
  });

  group('usesLocalizedContent', () {
    test('only an explicit System consults the localized pair', () {
      expect(MessageType.system.usesLocalizedContent, isTrue);
    });

    test('user and unknown both fall through to plain content', () {
      // `unknown` behaving like `user` is what makes "type missing → use
      // content" structural instead of a rule each call site must remember.
      expect(MessageType.user.usesLocalizedContent, isFalse);
      expect(MessageType.unknown.usesLocalizedContent, isFalse);
    });
  });
}
