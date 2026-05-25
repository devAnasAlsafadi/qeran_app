import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/presentation/widgets/like_countdown_formatter.dart';
import 'package:qeran/generated/locale_keys.g.dart';

void main() {
  group('LikeCountdownFormatter.resolve — bucketing', () {
    test('> 24 h → days + hours key with both args', () {
      // 1 day + 22 hours = 86400 + 22 * 3600 = 165600 s.
      final r = LikeCountdownFormatter.resolve(165600);
      expect(r.key, LocaleKeys.likes_time_left_days_hours);
      expect(r.args, {'days': '1', 'hours': '22'});
    });

    test('exactly 24 h → still days bucket (1d 0h)', () {
      final r = LikeCountdownFormatter.resolve(24 * 3600);
      expect(r.key, LocaleKeys.likes_time_left_days_hours);
      expect(r.args, {'days': '1', 'hours': '0'});
    });

    test('1 h ≤ t < 24 h → hours + minutes', () {
      // 2 h 15 m = 8100 s.
      final r = LikeCountdownFormatter.resolve(8100);
      expect(r.key, LocaleKeys.likes_time_left_hours_minutes);
      expect(r.args, {'hours': '2', 'minutes': '15'});
    });

    test('< 1 h → minutes only', () {
      final r = LikeCountdownFormatter.resolve(45 * 60);
      expect(r.key, LocaleKeys.likes_time_left_minutes);
      expect(r.args, {'minutes': '45'});
    });

    test('1 ≤ t < 60 s → "soon" key with no args', () {
      final r = LikeCountdownFormatter.resolve(30);
      expect(r.key, LocaleKeys.likes_time_left_soon);
      expect(r.args, isEmpty);
    });

    test('0 → status_expired (chip reuses the existing expired label)', () {
      expect(
        LikeCountdownFormatter.resolve(0).key,
        LocaleKeys.likes_status_expired,
      );
    });

    test('negative → status_expired (defensive)', () {
      expect(
        LikeCountdownFormatter.resolve(-10).key,
        LocaleKeys.likes_status_expired,
      );
    });
  });
}
