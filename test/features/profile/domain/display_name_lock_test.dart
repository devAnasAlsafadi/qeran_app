import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/profile/domain/entities/display_name_lock.dart';

/// The 7-day cooldown countdown. The load-bearing property is that it never
/// promises the name is editable sooner than it is.
void main() {
  final now = DateTime.utc(2026, 8, 12, 12);

  int? daysOf(NameLockRemaining r) => r is NameLockDays ? r.days : null;
  int? hoursOf(NameLockRemaining r) => r is NameLockHours ? r.hours : null;

  test('a full 7-day window reads as 7 days', () {
    final r = nameLockRemaining(now.add(const Duration(days: 7)), now);
    expect(daysOf(r), 7);
  });

  test('a partial day rounds UP, never down', () {
    // 6d5h left. Reporting 6 would tell the user to come back a day early,
    // where they would be rejected again.
    final r = nameLockRemaining(
      now.add(const Duration(days: 6, hours: 5)),
      now,
    );
    expect(daysOf(r), 7);
  });

  test('just over 24 hours is still counted in days', () {
    final r = nameLockRemaining(
      now.add(const Duration(hours: 24, minutes: 1)),
      now,
    );
    expect(daysOf(r), 2, reason: 'rounds up out of the 24h boundary');
  });

  test('exactly 24 hours switches to hours rather than reading 1 day', () {
    final r = nameLockRemaining(now.add(const Duration(hours: 24)), now);
    expect(hoursOf(r), 24);
  });

  test('the last day is counted in hours', () {
    final r = nameLockRemaining(now.add(const Duration(hours: 5)), now);
    expect(hoursOf(r), 5);
  });

  test('a sub-hour remainder still reports one hour, never zero', () {
    // "0" of anything reads as "now", which is the one thing it is not.
    final r = nameLockRemaining(now.add(const Duration(minutes: 1)), now);
    expect(hoursOf(r), 1);
  });

  test('an elapsed window reports elapsed', () {
    expect(nameLockRemaining(now, now), isA<NameLockElapsed>());
    expect(
      nameLockRemaining(now.subtract(const Duration(days: 3)), now),
      isA<NameLockElapsed>(),
    );
  });

  test('the boundary is the same instant regardless of device zone', () {
    // The server sends an instant; a device in another zone must not shift it.
    final until = DateTime.utc(2026, 8, 19, 12);
    final asLocal = until.toLocal();
    expect(
      daysOf(nameLockRemaining(until, now)),
      daysOf(nameLockRemaining(asLocal, now)),
    );
  });
}
