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

  // THE one. `matchJourneyHasEnded` is the right predicate everywhere else in
  // this feature and the wrong one here, and this is the single card that
  // tells them apart: declining the formal step moves the STAGE and leaves the
  // status Active. The server tiers on the status, so this card is tier 0 to
  // it. Tier it as ended and our list disagrees with the server's on every
  // fetch.
  test('a declined formal step keeps its ACTIVE tier, as the server has it', () {
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
          'tiered through the ending predicate rather than caseStatus. The '
          'server calls this case Active and puts it first; we would sink it, '
          'and the row would jump on the next refresh.',
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
