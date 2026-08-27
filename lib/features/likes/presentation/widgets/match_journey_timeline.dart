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
/// still to come. Every node is reachable as the current one, the first
/// included — a freshly accepted like stands on it with nothing behind it yet.
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
/// so from the member's side the journey is still moving.
///
/// It is unreachable BY CONSTRUCTION: [matchJourneyStage] answers where the
/// couple got to and says nothing about how it went there, so a declined
/// formal step and a live one arrive here as the same value. Adding a branch
/// would mean giving this function an outcome to read — which is exactly how
/// the dead ends this feature hides would come back.
///
/// `match_journey_timeline_test.dart` sweeps every server stage and every
/// legacy stage x formal-status pair and fails if any node comes back `ended`.
QeranStepTone _toneOf(MatchJourneyStage current) =>
    current == MatchJourneyStage.marriageCompleted
    ? QeranStepTone.success
    : QeranStepTone.normal;

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
String matchJourneyLabelKey(MatchJourneyStage stage) => switch (stage) {
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
