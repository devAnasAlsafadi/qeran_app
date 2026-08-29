import 'match_card.dart';
import 'match_case_status.dart';

/// The order the Matches tab renders in: whatever moved most recently, first.
///
/// This is a local copy of the server's `ORDER BY`, not a client opinion about
/// ordering:
///
/// ```sql
/// ORDER BY (caseStatus == Active ? 0 : 1),  -- tier
///          lastActivityAt DESC,             -- last activity
///          id DESC                          -- stable tiebreak
/// ```
///
/// Keeping our own copy is what stops the rendered list drifting from the one
/// the server sent, the way the matchmaker's conversation list mirrors its own
/// `lastMessageAt DESC`. Any disagreement between the two shows up as rows
/// settling in one position and jumping on the next fetch.
///
/// Before the field is deployed every timestamp is null, and this degrades to
/// tier then id — still deterministic, which is more than the arbitrary order
/// it replaces.
List<MatchCard> matchCardsByLastActivity(Iterable<MatchCard> cards) {
  final ordered = cards.toList();
  ordered.sort(_byLastActivity);
  return ordered;
}

int _byLastActivity(MatchCard a, MatchCard b) {
  final tierA = _tier(a);
  final tierB = _tier(b);
  if (tierA != tierB) return tierA.compareTo(tierB);

  final movedA = a.lastActivityAt;
  final movedB = b.lastActivityAt;
  if (movedA == null && movedB != null) return 1;
  if (movedB == null && movedA != null) return -1;
  if (movedA != null && movedB != null) {
    final byActivity = movedB.compareTo(movedA);
    if (byActivity != 0) return byActivity;
  }

  // Not decoration. Without it two cases sharing a timestamp order by whatever
  // the sort happens to do that run, so the list reshuffles between identical
  // fetches — the same instability that had to be fixed in the discovery deck.
  return b.likeRequestId.compareTo(a.likeRequestId);
}

/// Active cases above finished ones.
///
/// ⚠️ Read off `caseStatus` ALONE, deliberately, and NOT through
/// `matchJourneyHasEnded` — which is the better predicate everywhere else in
/// this feature and is the wrong one here.
///
/// They disagree on exactly one case: declining the formal step moves
/// `caseStage` to `formalStepRejected` and leaves `caseStatus` **Active**. The
/// server's tier reads the status, so it puts that card in tier 0; our
/// ending predicate would put it in tier 1. Use ours and the two orders differ
/// on every fetch — the card lands in one place, then jumps when the list
/// refreshes. Matching the server matters more here than being right in
/// isolation.
///
/// `unknown` lands in tier 1, with the rest of `!= Active`. That is a knowing
/// departure from this feature's rule that an unrecognised status OMITS rather
/// than guesses: omitting is not available to a comparator, since every card
/// must be placed somewhere, and any placement other than the server's
/// reintroduces the jump.
int _tier(MatchCard card) =>
    card.caseStatus == MatchCaseStatus.active ? 0 : 1;
