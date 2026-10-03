import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/relative_time.dart';
import 'package:qeran/core/utils/server_clock.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../shipped_strings_rig.dart';

final _now = DateTime.utc(2026, 10, 1, 12);

const _second = Duration(seconds: 1);
const _minute = Duration(minutes: 1);
const _hour = Duration(hours: 1);
const _day = Duration(days: 1);

/// What [elapsed] before [_now] reads as.
String _ago(BuildContext context, Duration elapsed, {bool compact = false}) =>
    QeranRelativeTime.ago(
      _now.subtract(elapsed),
      context,
      now: _now,
      compact: compact,
    )!;

/// Every bucket and every Arabic plural category it reaches (Q6, B1).
final _arabic = <Duration, String>{
  Duration.zero: 'الآن',
  _second * 59: 'الآن',
  _minute * -5: 'الآن', // a clock still a little behind the server
  _minute: 'منذ دقيقة',
  _minute * 2: 'منذ دقيقتين',
  _minute * 3: 'منذ 3 دقائق',
  _minute * 10: 'منذ 10 دقائق',
  _minute * 11: 'منذ 11 دقيقة',
  _minute * 59: 'منذ 59 دقيقة',
  _hour: 'منذ ساعة',
  _hour * 2: 'منذ ساعتين',
  _hour * 5: 'منذ 5 ساعات',
  _hour * 11: 'منذ 11 ساعة',
  _hour * 23: 'منذ 23 ساعة',
  _day: 'أمس',
  _day * 2: 'منذ يومين',
  _day * 3: 'منذ 3 أيام',
  _day * 6: 'منذ 6 أيام',
  _day * 7: 'منذ أسبوع',
  _day * 14: 'منذ أسبوعين',
  _day * 21: 'منذ 3 أسابيع',
  _day * 34: 'منذ 4 أسابيع',
  _day * 35: '2026/08/27',
};

/// English, long (cards) and compact (rows).
final _english = <Duration, (String, String)>{
  Duration.zero: ('Just now', 'Just now'),
  _minute: ('1 minute ago', '1m'),
  _minute * 5: ('5 minutes ago', '5m'),
  _hour: ('1 hour ago', '1h'),
  _hour * 2: ('2 hours ago', '2h'),
  _day: ('Yesterday', '1d'),
  _day * 3: ('3 days ago', '3d'),
  _day * 7: ('1 week ago', '1w'),
  _day * 28: ('4 weeks ago', '4w'),
  _day * 35: ('2026/08/27', '2026/08/27'),
};

/// From a day on, what counts is the local calendar dates, not the hours
/// between them: (posted, now) in the device's time → Arabic, English long,
/// English compact.
final _calendar = <(DateTime, DateTime), (String, String, String)>{
  // The emulator's 3 October: 47 hours, but two dates back.
  (DateTime(2026, 10, 1, 10), DateTime(2026, 10, 3, 9)): (
    'منذ يومين',
    '2 days ago',
    '2d',
  ),
  // 24 hours and a bit, one date back; and 47 hours, still one date back.
  (DateTime(2026, 10, 1, 23, 30), DateTime(2026, 10, 2, 23, 45)): (
    'أمس',
    'Yesterday',
    '1d',
  ),
  (DateTime(2026, 10, 1, 0, 10), DateTime(2026, 10, 2, 23, 50)): (
    'أمس',
    'Yesterday',
    '1d',
  ),
  // 24 hours and 20 minutes, two dates back.
  (DateTime(2026, 10, 1, 23, 50), DateTime(2026, 10, 3, 0, 10)): (
    'منذ يومين',
    '2 days ago',
    '2d',
  ),
  // Under a day stays in hours, even across midnight.
  (DateTime(2026, 10, 2, 22), DateTime(2026, 10, 3, 8)): (
    'منذ 10 ساعات',
    '10 hours ago',
    '10h',
  ),
  // Across a month and a year.
  (DateTime(2026, 9, 30, 20), DateTime(2026, 10, 2, 8)): (
    'منذ يومين',
    '2 days ago',
    '2d',
  ),
  (DateTime(2026, 12, 31, 22), DateTime(2027, 1, 2, 9)): (
    'منذ يومين',
    '2 days ago',
    '2d',
  ),
  // Weeks are counted in dates too: 6 days and 2 hours is 7 dates back…
  (DateTime(2026, 9, 26, 23), DateTime(2026, 10, 3, 1)): (
    'منذ أسبوع',
    '1 week ago',
    '1w',
  ),
  (DateTime(2026, 9, 19, 23), DateTime(2026, 10, 3, 1)): (
    'منذ أسبوعين',
    '2 weeks ago',
    '2w',
  ),
  // …and so is the date: 34 days and 2 hours is 35 dates back.
  (DateTime(2026, 8, 29, 23), DateTime(2026, 10, 3, 1)): (
    '2026/08/29',
    '2026/08/29',
    '2026/08/29',
  ),
};

void main() {
  setUpAll(initShippedStrings);

  testWidgets('Arabic: every bucket, every plural form', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('ar'));
    for (final MapEntry(key: elapsed, value: text) in _arabic.entries) {
      expect(_ago(context, elapsed), text, reason: '$elapsed');
    }
  });

  testWidgets('Arabic rows read as long as cards (Q6)', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('ar'));
    for (final elapsed in _arabic.keys) {
      expect(
        _ago(context, elapsed, compact: true),
        _arabic[elapsed],
        reason: '$elapsed',
      );
    }
  });

  testWidgets('English: long on cards, short in rows', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('en'));
    for (final MapEntry(key: elapsed, value: (long, short))
        in _english.entries) {
      expect(_ago(context, elapsed), long, reason: '$elapsed');
      expect(_ago(context, elapsed, compact: true), short, reason: '$elapsed');
    }
  });

  group('from a day on, calendar dates', () {
    for (final locale in ['ar', 'en']) {
      testWidgets(locale, (tester) async {
        final context = await pumpShippedStrings(tester, Locale(locale));
        for (final MapEntry(key: (at, now), value: (ar, en, short))
            in _calendar.entries) {
          String ago({bool compact = false}) =>
              QeranRelativeTime.ago(at, context, now: now, compact: compact)!;
          if (locale == 'ar') {
            expect(ago(), ar, reason: '$at → $now');
            expect(ago(compact: true), ar, reason: '$at → $now');
          } else {
            expect(ago(), en, reason: '$at → $now');
            expect(ago(compact: true), short, reason: '$at → $now');
          }
        }
      });
    }

    test('a day of a clock change has 25 hours: still the same date reads '
        'in hours, not "Yesterday"', () {
      const elapsed = Duration(hours: 24, minutes: 30);
      expect(QeranRelativeTime.unit(elapsed, 0), (
        24,
        LocaleKeys.time_hours_ago,
        LocaleKeys.time_hours_ago_compact,
      ));
      expect(QeranRelativeTime.unit(elapsed, 1).$1, 1);
    });
  });

  testWidgets('no time, no line', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('en'));
    expect(QeranRelativeTime.ago(null, context), isNull);
  });

  testWidgets('measured on the server clock: a phone two hours fast still '
      'calls a post made a moment ago "Just now"', (tester) async {
    addTearDown(ServerClock.resetForTest);
    final device = DateTime.now().toUtc();
    final server = device.subtract(_hour * 2);
    ServerClock.instance.calibrate(
      expiresAt: server.add(_minute * 10),
      remainingSeconds: 600,
    );
    final context = await pumpShippedStrings(tester, const Locale('en'));

    expect(QeranRelativeTime.ago(server, context), 'Just now');
  });
}
