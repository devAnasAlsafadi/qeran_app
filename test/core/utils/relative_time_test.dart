import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/relative_time.dart';
import 'package:qeran/core/utils/server_clock.dart';

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
