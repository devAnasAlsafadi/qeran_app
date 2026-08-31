import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_card_order.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_case_status.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';

/// The Matches tab renders a local copy of the server's `ORDER BY`:
/// tier, then `lastActivityAt` DESC, then id DESC.
///
/// Everything here is really one claim — that our copy and the server's rule
/// produce the same list — because the cost of them differing is not a wrong
/// order but a MOVING one: rows settle where we put them and jump where the
/// server puts them on the next fetch.
MatchCard _card(
  int id, {
  DateTime? at,
  MatchCaseStatus status = MatchCaseStatus.active,
  MatchCaseStage stage = MatchCaseStage.unknown,
}) => MatchCard(
  likeRequestId: id,
  otherUserId: 'u$id',
  otherUserName: 'User $id',
  images: const [],
  stage: MatchStage.photosExchanged,
  pendingPhotoExchange: null,
  formalRequest: null,
  conversationId: null,
  caseStage: stage,
  caseStatus: status,
  lastActivityAt: at,
);

List<int> _ids(Iterable<MatchCard> cards) =>
    cards.map((c) => c.likeRequestId).toList();

DateTime _at(int day) => DateTime.utc(2026, 8, day);

void main() {
  group('newest activity first', () {
    test('among active cases, the most recent rises', () {
      final ordered = matchCardsByLastActivity([
        _card(1, at: _at(1)),
        _card(2, at: _at(9)),
        _card(3, at: _at(5)),
      ]);

      expect(_ids(ordered), [2, 3, 1]);
    });

    test('a card that never moved sorts below one that did', () {
      final ordered = matchCardsByLastActivity([
        _card(1),
        _card(2, at: _at(1)),
      ]);

      expect(_ids(ordered), [2, 1]);
    });
  });

  group('active cases sit above finished ones', () {
    // Whatever it says about how recently it moved: an ended case has nothing
    // left to do, and ending is itself an event, so ordering on activity alone
    // would put the one card needing no answer above every card that does.
    for (final ended in const [
      MatchCaseStatus.cancelled,
      MatchCaseStatus.failed,
      MatchCaseStatus.completed,
      MatchCaseStatus.unknown,
    ]) {
      test('${ended.name} stays below an older active case', () {
        final ordered = matchCardsByLastActivity([
          _card(1, at: _at(20), status: ended),
          _card(2, at: _at(2)),
        ]);

        expect(
          _ids(ordered),
          [2, 1],
          reason: '${ended.name} sorted above a live case',
        );
      });
    }
  });

  // A SYNTHETIC card, and deliberately so: an active `caseStatus` alongside a
  // rejected formal step is a pairing the server does not send — declining
  // sets `Cancelled`. Holding the status active is exactly what isolates the
  // one question this test asks: which field does `_tier` read? Tier through
  // `matchJourneyHasEnded` and the stage sinks a card the status calls live.
  //
  // Belt to the braces of the `completed` and `unknown` cases above, which
  // kill the same mutation on payloads that ARE real (verified by running it).
  // Kept because it pins the field directly, rather than depending on which
  // values happen to co-occur.
  test('the tier reads caseStatus, not the stage', () {
    final ordered = matchCardsByLastActivity([
      _card(1, at: _at(2)),
      _card(
        2,
        at: _at(9),
        stage: MatchCaseStage.formalStepRejected,
      ),
    ]);

    expect(
      _ids(ordered),
      [2, 1],
      reason:
          'tiered through the ending predicate rather than caseStatus. This '
          'card is active by status, so the server puts it first; reading the '
          'stage instead sinks it, and the row jumps on the next refresh.',
    );
  });

  group('the order is stable', () {
    // Built as stability rather than as a fixed sequence on purpose: a
    // fixed-order assertion on equal keys can pass by luck on one input.
    test('cards sharing a timestamp order the same from any input order', () {
      final at = _at(4);
      final forwards = matchCardsByLastActivity([
        _card(1, at: at),
        _card(2, at: at),
        _card(3, at: at),
      ]);
      final backwards = matchCardsByLastActivity([
        _card(3, at: at),
        _card(2, at: at),
        _card(1, at: at),
      ]);
      final shuffled = matchCardsByLastActivity([
        _card(2, at: at),
        _card(1, at: at),
        _card(3, at: at),
      ]);

      expect(_ids(forwards), _ids(backwards));
      expect(_ids(forwards), _ids(shuffled));
      expect(_ids(forwards), [3, 2, 1]);
    });

    test('cards with no timestamp at all still order the same way', () {
      expect(
        _ids(matchCardsByLastActivity([_card(1), _card(3), _card(2)])),
        _ids(matchCardsByLastActivity([_card(2), _card(1), _card(3)])),
      );
    });
  });

  test('the input list is not mutated', () {
    final input = [_card(1, at: _at(1)), _card(2, at: _at(9))];
    matchCardsByLastActivity(input);

    expect(_ids(input), [1, 2]);
  });
}
