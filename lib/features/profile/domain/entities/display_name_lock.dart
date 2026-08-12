/// How much of the display-name cooldown is left, in the unit the UI shows.
///
/// Days alone cannot express the last stretch — under 24 hours it would read
/// "0 days", which the user reads as "now". So the final day is counted in
/// hours instead.
sealed class NameLockRemaining {
  const NameLockRemaining();
}

/// More than 24 hours left.
final class NameLockDays extends NameLockRemaining {
  final int days;
  const NameLockDays(this.days);
}

/// 24 hours or less left, but not yet elapsed.
final class NameLockHours extends NameLockRemaining {
  final int hours;
  const NameLockHours(this.hours);
}

/// The cooldown has elapsed — nothing to count down.
final class NameLockElapsed extends NameLockRemaining {
  const NameLockElapsed();
}

/// Remaining cooldown from [now] to [until].
///
/// Both units round UP: with 6 days and 5 hours left, "6 days" would be a
/// promise the user discovers is false by trying on day 6, so it reports 7.
/// The same applies within the last day, where anything above zero reports at
/// least one hour.
NameLockRemaining nameLockRemaining(DateTime until, DateTime now) {
  // Compare in UTC — `displayNameLockedUntil` is a server instant, and a
  // device in a different zone must not shift the boundary.
  final delta = until.toUtc().difference(now.toUtc());
  if (delta <= Duration.zero) return const NameLockElapsed();
  if (delta > const Duration(hours: 24)) {
    return NameLockDays(_ceilDivide(delta.inMinutes, Duration.minutesPerDay));
  }
  return NameLockHours(_ceilDivide(delta.inMinutes, Duration.minutesPerHour));
}

int _ceilDivide(int value, int divisor) => (value + divisor - 1) ~/ divisor;
