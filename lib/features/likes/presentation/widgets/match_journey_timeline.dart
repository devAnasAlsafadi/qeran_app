import 'package:qeran/core/design_system/widgets/qeran_stepper.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import '../../domain/entities/match_journey.dart';
import '../../domain/entities/match_journey_outcome.dart';

/// One node of the member's compatibility-journey timeline: which [stage] it
/// stands for, what it says, and how it should draw.
///
/// Carries a label KEY rather than resolved words so the projection stays
/// context-free and unit-testable — turning a key into text needs a
/// BuildContext, and that is the card's job, not this one's.
///
/// The key rides WITH the tone rather than being looked up separately by
/// whoever draws it, following the matchmaker's `CaseTimelineStep` and for its
/// reason: an ended node says something other than the stage it stands on, and
/// two properties describing one fact, resolved independently, is exactly how
/// they come to disagree. The card draws this twice — the collapsed summary
/// and the open timeline — so "resolved once" is not academic here.
class MatchJourneyStep {
  const MatchJourneyStep({
    required this.stage,
    required this.labelKey,
    required this.state,
    required this.tone,
  });

  final MatchJourneyStage stage;
  final String labelKey;
  final QeranStepState state;
  final QeranStepTone tone;
}

/// Projects [card] onto all five journey nodes, in order.
///
/// Everything before the card's current stage is done, everything after is
/// still to come. Every node is reachable as the current one, the first
/// included — a freshly accepted like stands on it with nothing behind it yet.
///
/// The tone and the ending label belong to the CURRENT node alone. A done or a
/// future node describes a step rather than an outcome, and carrying either
/// down the column would announce the same ending five times.
List<MatchJourneyStep> buildMatchJourney(MatchCard card) {
  final current = matchJourneyStage(card);
  final index = current.index;
  final tone = _toneOf(current, matchJourneyHasEnded(card));
  final ended = tone == QeranStepTone.ended;

  return [
    for (var i = 0; i < MatchJourneyStage.values.length; i++)
      MatchJourneyStep(
        stage: MatchJourneyStage.values[i],
        labelKey: i == index && ended
            ? LocaleKeys.likes_matches_journey_ended
            : _labelKeyOf(MatchJourneyStage.values[i]),
        state: i < index
            ? QeranStepState.done
            : i == index
            ? QeranStepState.current
            : QeranStepState.future,
        tone: i == index ? tone : QeranStepTone.normal,
      ),
  ];
}

/// Tone of the current node.
///
/// ⚠️ BUSINESS RULE — the `ended` branch is NARROW. Widening it is the
/// regression to watch for here, and it used to be absent entirely.
///
/// The matchmaker's timeline draws a danger cross for a rejected photo
/// exchange, a lapsed one, a closed case and a cancelled one. The member's
/// draws it for THREE outcomes, the ones `matchJourneyHasEnded` holds: the
/// member cancelled, the matchmaker recorded «لم ينجح», or the receiver
/// declined the formal step. A declined or lapsed photo exchange stays
/// NORMAL — the matchmaker takes the couple over and keeps working, so from
/// the member's side that journey really is still moving. That case is why
/// this projection carried no ended branch at all until the interactive
/// journey gave a member ways to genuinely stop one, and it is the reason the
/// reversal had to be narrow rather than a switch to the matchmaker's rule.
///
/// The marriage node WINS over an ending, deliberately. `caseStage` is how far
/// the couple got, and standing on that node means the marriage happened; a
/// `Cancelled` or `Failed` status arriving beside it is contradictory server
/// state, and of the two wrong answers a danger cross on a wedding is much the
/// worse. `completed` is not an ending this function reads at all — the
/// success tone owns it, and keeping them apart is what stops a finished
/// marriage from being drawn as a failure.
///
/// `match_journey_timeline_test.dart` sweeps every server stage, every status
/// and every legacy stage x formal-status pair, and fails BOTH ways: if one of
/// the three stops ending, and if anything else starts.
QeranStepTone _toneOf(MatchJourneyStage current, bool ended) {
  if (current == MatchJourneyStage.marriageCompleted) {
    return QeranStepTone.success;
  }
  return ended ? QeranStepTone.ended : QeranStepTone.normal;
}

/// The member's word for each node. The nodes are the matchmaker's five and
/// so are the WORDS now — `matchmaker.cases_timeline_*` carries the same five
/// strings, so a member and the matchmaker reading the same case describe it
/// the same way.
///
/// Two key sets rather than one shared set, deliberately: nothing else in
/// `lib/features/matchmaker` reads a `likes_` key, and this is not the place
/// to start. The pairing is held by the matching suffixes — grep
/// `formal_contact` and both sides come back together.
///
/// The matchmaker's used to say something different, because its nodes
/// borrowed keys that are also its status chips and could not be reworded for
/// one screen without moving under the other. Those five are forked now, and
/// `case_timeline_test.dart` fails if one is pointed back at a borrowed key.
///
/// Private: [MatchJourneyStep] now carries the resolved key, so the only
/// caller is [buildMatchJourney] and the mapping is pinned through the path
/// that actually ships rather than by reaching past it.
String _labelKeyOf(MatchJourneyStage stage) => switch (stage) {
  MatchJourneyStage.initialCompatibility =>
    LocaleKeys.likes_matches_journey_initial_compatibility,
  MatchJourneyStage.photoExchange =>
    LocaleKeys.likes_matches_journey_photo_exchange,
  MatchJourneyStage.formalContact =>
    LocaleKeys.likes_matches_journey_formal_contact,
  MatchJourneyStage.formalMeeting =>
    LocaleKeys.likes_matches_journey_formal_meeting,
  MatchJourneyStage.marriageCompleted =>
    LocaleKeys.likes_matches_journey_marriage_completed,
};
