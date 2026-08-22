import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/match_formal_status.dart';

/// `formalRequest.status` has been seen arriving as the PascalCase name and as
/// a numeric code, so both shapes have to land on the same member.
void main() {
  const byName = {
    'WaitingForParentAppointment':
        MatchFormalStatus.waitingForParentAppointment,
    'ParentsVisited': MatchFormalStatus.parentsVisited,
    'SuccessfullyClosed': MatchFormalStatus.successfullyClosed,
    'CompatibilityClosed': MatchFormalStatus.compatibilityClosed,
    'CompatibilityCancelled': MatchFormalStatus.compatibilityCancelled,
  };

  // 1-BASED. A 0-based reading would shift every member by one and put someone
  // who is nearly done back at the start of the formal track, raising nothing
  // anywhere.
  const byCode = {
    1: MatchFormalStatus.waitingForParentAppointment,
    2: MatchFormalStatus.parentsVisited,
    3: MatchFormalStatus.successfullyClosed,
    4: MatchFormalStatus.compatibilityClosed,
    5: MatchFormalStatus.compatibilityCancelled,
  };

  test('reads every PascalCase name', () {
    byName.forEach((raw, expected) {
      expect(MatchFormalStatus.fromWire(raw), expected, reason: raw);
    });
  });

  test('reads every numeric code, and they are 1-based', () {
    byCode.forEach((code, expected) {
      expect(MatchFormalStatus.fromWire(code), expected, reason: '$code');
    });
    expect(MatchFormalStatus.fromWire(0), MatchFormalStatus.unknown);
  });

  test('the two shapes agree member for member', () {
    for (final entry in byCode.entries) {
      final name = byName.entries.firstWhere((e) => e.value == entry.value).key;
      expect(
        MatchFormalStatus.fromWire(name),
        MatchFormalStatus.fromWire(entry.key),
        reason: name,
      );
    }
  });

  // A numeric code arriving quoted is the shape most likely to slip through
  // untyped JSON.
  test('a numeric code inside a string still parses', () {
    expect(
      MatchFormalStatus.fromWire('3'),
      MatchFormalStatus.successfullyClosed,
    );
  });

  test('casing is not load-bearing', () {
    expect(
      MatchFormalStatus.fromWire('successfullyclosed'),
      MatchFormalStatus.successfullyClosed,
    );
    expect(
      MatchFormalStatus.fromWire('SUCCESSFULLYCLOSED'),
      MatchFormalStatus.successfullyClosed,
    );
  });

  test('anything unrecognised is unknown, never a wrong member', () {
    for (final raw in [null, '', 'Whatever', 9, -1, 3.5, <String>[]]) {
      expect(
        MatchFormalStatus.fromWire(raw),
        MatchFormalStatus.unknown,
        reason: '$raw',
      );
    }
  });
}
