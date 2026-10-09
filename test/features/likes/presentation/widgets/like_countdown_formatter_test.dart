import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/presentation/widgets/like_countdown_formatter.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../../core/shipped_strings_rig.dart';

const _day = 24 * 3600;
const _hour = 3600;
const _minute = 60;

void main() {
  group('LikeCountdownFormatter.resolve — bucketing', () {
    test('> 24 h → days + hours', () {
      final r = LikeCountdownFormatter.resolve(_day + 22 * _hour);
      expect(r.parts, [
        (key: LocaleKeys.likes_countdown_days, n: 1),
        (key: LocaleKeys.likes_countdown_hours, n: 22),
      ]);
    });

    test('exactly 24 h → days alone: a zero hour is left out', () {
      final r = LikeCountdownFormatter.resolve(_day);
      expect(r.parts, [(key: LocaleKeys.likes_countdown_days, n: 1)]);
    });

    test('1 h ≤ t < 24 h → hours + minutes', () {
      final r = LikeCountdownFormatter.resolve(2 * _hour + 15 * _minute);
      expect(r.parts, [
        (key: LocaleKeys.likes_countdown_hours, n: 2),
        (key: LocaleKeys.likes_countdown_minutes, n: 15),
      ]);
    });

    test('< 1 h → minutes only', () {
      final r = LikeCountdownFormatter.resolve(45 * _minute);
      expect(r.parts, [(key: LocaleKeys.likes_countdown_minutes, n: 45)]);
    });

    test('1 ≤ t < 60 s → "soon", no parts', () {
      final r = LikeCountdownFormatter.resolve(30);
      expect(r.label, LocaleKeys.likes_time_left_soon);
      expect(r.parts, isEmpty);
    });

    test('0 → status_expired (chip reuses the existing expired label)', () {
      expect(
        LikeCountdownFormatter.resolve(0).label,
        LocaleKeys.likes_status_expired,
      );
    });

    test('negative → status_expired (defensive)', () {
      expect(
        LikeCountdownFormatter.resolve(-10).label,
        LocaleKeys.likes_status_expired,
      );
    });
  });

  // The shipped strings, plural rules on as in main.dart (B1's forms).
  group('LikeCountdownFormatter.format — the words', () {
    setUpAll(initShippedStrings);

    const arabic = {
      _day: 'يوم',
      2 * _day: 'يومان',
      6 * _day + 13 * _hour: '6 أيام و13 ساعة',
      11 * _day + 2 * _hour: '11 يوماً وساعتان',
      100 * _day + _hour: '100 يوم وساعة',
      4 * _hour: '4 ساعات',
      11 * _hour + 3 * _minute: '11 ساعة و3 دقائق',
      23 * _hour + 59 * _minute: '23 ساعة و59 دقيقة',
      _minute: 'دقيقة',
      2 * _minute: 'دقيقتان',
      10 * _minute: '10 دقائق',
      45 * _minute: '45 دقيقة',
    };
    const english = {
      6 * _day + 13 * _hour: '6d 13h',
      _day: '1d',
      2 * _hour + 15 * _minute: '2h 15m',
      45 * _minute: '45m',
    };

    for (final (locale, cases) in [
      (const Locale('ar'), arabic),
      (const Locale('en'), english),
    ]) {
      testWidgets('[${locale.languageCode}]', (tester) async {
        final context = await pumpShippedStrings(tester, locale);
        for (final MapEntry(key: seconds, value: words) in cases.entries) {
          expect(
            LikeCountdownFormatter.format(context, seconds),
            words,
            reason: '$seconds s',
          );
        }
      });
    }
  });
}
