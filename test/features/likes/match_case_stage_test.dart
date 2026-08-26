import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_case_status.dart';

/// `caseStage` and `caseStatus` arrived with the interactive journey, and both
/// are read defensively — an unrecognised value degrades rather than throwing.
/// That is the right behaviour and also the dangerous one: a spelling the
/// client does not know produces a perfectly quiet wrong answer.
///
/// These pin the vocabulary so a rename on the server side is a failing test
/// rather than a member watching their journey sit on the wrong node.
void main() {
  group('MatchCaseStage — names', () {
    const byName = <String, MatchCaseStage>{
      'LikeAccepted': MatchCaseStage.likeAccepted,
      'PhotoExchangePending': MatchCaseStage.photoExchangePending,
      'PhotoExchangeAccepted': MatchCaseStage.photoExchangeAccepted,
      'PhotoExchangeRejected': MatchCaseStage.photoExchangeRejected,
      'PhotoExchangeExpired': MatchCaseStage.photoExchangeExpired,
      'FormalStepPending': MatchCaseStage.formalStepPending,
      'FormalStepRejected': MatchCaseStage.formalStepRejected,
      'FormalStepExpired': MatchCaseStage.formalStepExpired,
      'AwaitingMatchmakerCoordination':
          MatchCaseStage.awaitingMatchmakerCoordination,
      'ParentsVisited': MatchCaseStage.parentsVisited,
      'MarriageCompleted': MatchCaseStage.marriageCompleted,
    };

    test('covers every member except the fallback', () {
      expect(
        byName.values.toSet(),
        MatchCaseStage.values.toSet()..remove(MatchCaseStage.unknown),
      );
    });

    for (final entry in byName.entries) {
      test('${entry.key} parses', () {
        expect(MatchCaseStage.fromWire(entry.key), entry.value);
      });
    }

    test('case does not matter', () {
      expect(
        MatchCaseStage.fromWire('awaitingmatchmakercoordination'),
        MatchCaseStage.awaitingMatchmakerCoordination,
      );
    });
  });

  // The codes are 0-BASED here and 1-based on the formalRequest status that
  // rides the same payload. This is the test that would catch the two being
  // confused.
  group('MatchCaseStage — numeric fallback is 0-based', () {
    test('0 is LikeAccepted, not the first formal stage', () {
      expect(MatchCaseStage.fromWire(0), MatchCaseStage.likeAccepted);
    });

    test('every code 0..10 maps in declaration order', () {
      for (var code = 0; code <= 10; code++) {
        expect(
          MatchCaseStage.fromWire(code),
          MatchCaseStage.values[code],
          reason: 'code $code',
        );
      }
    });

    test('numeric strings work too', () {
      expect(MatchCaseStage.fromWire('8'),
          MatchCaseStage.awaitingMatchmakerCoordination);
    });

    test('out of range and nonsense degrade to unknown', () {
      for (final raw in <Object?>[11, -1, 99, null, 'Nope', true, 3.5]) {
        expect(
          MatchCaseStage.fromWire(raw),
          MatchCaseStage.unknown,
          reason: '$raw',
        );
      }
    });

    test('unknown is never reachable by a valid code', () {
      // It sits last, so its index is one past the real values — a naive
      // range check would let `11` through as "unknown means unknown".
      expect(MatchCaseStage.fromWire(MatchCaseStage.unknown.index),
          MatchCaseStage.unknown);
    });
  });

  group('MatchCaseStatus', () {
    test('absent means active, not unknown', () {
      // A payload cached before the field shipped, or any row the server
      // leaves it off. Reading it as unknown would mark live cases ended.
      expect(MatchCaseStatus.fromWire(null), MatchCaseStatus.active);
      expect(MatchCaseStatus.fromWire(''), MatchCaseStatus.active);
    });

    test('the four states parse', () {
      expect(MatchCaseStatus.fromWire('Active'), MatchCaseStatus.active);
      expect(MatchCaseStatus.fromWire('Cancelled'), MatchCaseStatus.cancelled);
      expect(MatchCaseStatus.fromWire('Failed'), MatchCaseStatus.failed);
      expect(MatchCaseStatus.fromWire('Completed'), MatchCaseStatus.completed);
    });

    test('the American spelling parses too', () {
      expect(MatchCaseStatus.fromWire('Canceled'), MatchCaseStatus.cancelled);
    });

    test('present but unrecognised is unknown, NOT active', () {
      // The distinction that matters: a status we have never heard of must
      // not render as a healthy running case.
      expect(MatchCaseStatus.fromWire('Suspended'), MatchCaseStatus.unknown);
      expect(MatchCaseStatus.fromWire(7), MatchCaseStatus.unknown);
    });

    test('isEnded covers every terminal and nothing else', () {
      expect(MatchCaseStatus.active.isEnded, isFalse);
      expect(MatchCaseStatus.unknown.isEnded, isFalse);
      expect(MatchCaseStatus.cancelled.isEnded, isTrue);
      expect(MatchCaseStatus.failed.isEnded, isTrue);
      expect(MatchCaseStatus.completed.isEnded, isTrue);
    });
  });
}
