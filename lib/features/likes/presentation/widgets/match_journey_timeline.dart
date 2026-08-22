import 'package:qeran/core/design_system/widgets/qeran_stepper.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import '../../domain/entities/match_journey.dart';

/// One node of the member's compatibility-journey timeline: which [stage] it
/// stands for, and how it should draw.
///
/// Carries the STAGE rather than a resolved label so the projection stays
/// context-free and unit-testable — turning a stage into words is the card's
/// job, not this one's.
class MatchJourneyStep {
  const MatchJourneyStep({
    required this.stage,
    required this.state,
    required this.tone,
  });

  final MatchJourneyStage stage;
  final QeranStepState state;
  final QeranStepTone tone;
}

/// Projects [card] onto all five journey nodes, in order.
///
/// Everything before the card's current stage is done, everything after is
/// still to come. The first node is always done: [matchJourneyStage] never
/// returns [MatchJourneyStage.liked], because a match card exists only once a
/// like has been both sent and accepted.
List<MatchJourneyStep> buildMatchJourney(MatchCard card) {
  final current = matchJourneyStage(card);
  final index = current.index;

  return [
    for (var i = 0; i < MatchJourneyStage.values.length; i++)
      MatchJourneyStep(
        stage: MatchJourneyStage.values[i],
        state: i < index
            ? QeranStepState.done
            : i == index
            ? QeranStepState.current
            : QeranStepState.future,
        tone: i == index ? _toneOf(current) : QeranStepTone.normal,
      ),
  ];
}

/// Tone of the current node. Only two of the three values are reachable, and
/// that is the entire point of this projection.
///
/// ⚠️ BUSINESS RULE — DO NOT ADD A BRANCH FOR [QeranStepTone.ended] HERE.
///
/// The matchmaker's timeline draws a danger cross for a rejected photo
/// exchange, a closed case and a cancelled one. The member's must not, and the
/// missing branch is deliberate rather than unfinished: those are precisely
/// the outcomes where the matchmaker takes the couple over and keeps working,
/// so from the member's side the journey is still moving. [matchJourneyStage]
/// has already folded all three into
/// [MatchJourneyStage.matchmakerFollowUp] upstream, so no input can reach an
/// "ended" branch — adding one would mean re-introducing the dead ends this
/// feature exists to hide.
///
/// `match_journey_timeline_test.dart` sweeps every stage x formal-status pair
/// and fails if any node ever comes back carrying `ended`.
QeranStepTone _toneOf(MatchJourneyStage current) =>
    current == MatchJourneyStage.completed
    ? QeranStepTone.success
    : QeranStepTone.normal;

/// The member's word for each node. Deliberately NOT the matchmaker's:
/// `matchmaker.cases_formal_waiting_appointment` and `_parents_visited` name
/// steps the matchmaker works, and both live behind
/// [MatchJourneyStage.matchmakerFollowUp] here.
String matchJourneyLabelKey(MatchJourneyStage stage) => switch (stage) {
  MatchJourneyStage.liked => LocaleKeys.likes_matches_journey_liked,
  MatchJourneyStage.likeAccepted =>
    LocaleKeys.likes_matches_journey_like_accepted,
  MatchJourneyStage.photoExchange =>
    LocaleKeys.likes_matches_journey_photo_exchange,
  MatchJourneyStage.matchmakerFollowUp =>
    LocaleKeys.likes_matches_journey_matchmaker,
  MatchJourneyStage.completed => LocaleKeys.likes_matches_journey_completed,
};
