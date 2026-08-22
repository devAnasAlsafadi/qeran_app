import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_motion.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_disclosure.dart';
import 'package:qeran/core/design_system/widgets/qeran_stepper.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import 'match_journey_scope.dart';
import 'match_journey_timeline.dart';

/// The compatibility journey on a match card: the current stage on one line,
/// and the full five-node timeline when the member asks for it.
///
/// Collapsed by default, and that is the whole reason it is a disclosure.
/// Every card draws the same five labels, so an always-open timeline would
/// stack the identical five phrases down the whole list and add roughly 230px
/// to every card. Closed, it costs one line and still answers the only
/// question most members have: where are we now.
///
/// Under a [MatchJourneyScope] only one card may be open at a time; without
/// one each card keeps its own state.
class MatchJourneyCard extends StatelessWidget {
  const MatchJourneyCard({super.key, required this.card});

  final MatchCard card;

  @override
  Widget build(BuildContext context) {
    final steps = buildMatchJourney(card);
    final current = steps.firstWhere((s) => s.state == QeranStepState.current);

    final scope = MatchJourneyScope.maybeOf(context);

    return QeranDisclosure(
      expanded: scope?.isOpen(card.likeRequestId),
      onExpandedChanged: scope == null
          ? null
          : (open) {
              scope.onOpenChanged(card.likeRequestId, open);
              if (open) _reveal(context);
            },
      hint: LocaleKeys.likes_matches_journey_view.t(context),
      summary: _Summary(labelKey: matchJourneyLabelKey(current.stage)),
      child: Padding(
        padding: const EdgeInsets.only(top: QeranSpacing.s12),
        child: QeranStepper(
          steps: [
            for (final step in steps)
              QeranStepData(
                label: matchJourneyLabelKey(step.stage).t(context),
                state: step.state,
                tone: step.tone,
              ),
          ],
          currentLabel: LocaleKeys.likes_matches_journey_current.t(context),
        ),
      ),
    );
  }

  /// Opening one card closes another, and when the other sat ABOVE this one
  /// the list loses its height first — so this card's summary row slides up
  /// out from under the finger that just tapped it. Scrolling it back into
  /// place afterwards costs one frame and removes the jump entirely.
  ///
  /// Deferred to the next frame because the new height does not exist yet
  /// when the tap is reported.
  void _reveal(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0,
        duration: QeranMotion.standard,
        curve: QeranCurves.standard,
      );
    });
  }
}

/// The collapsed line: the current stage, named, with nothing in front of it.
///
/// The glyph is what separates this from the status line further up the card.
/// That line describes the situation ("Photos hidden until exchange"); this
/// one names the stage of the journey, and the two are meant to read as
/// different registers rather than as a repeat.
class _Summary extends StatelessWidget {
  const _Summary({required this.labelKey});

  final String labelKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.timeline_rounded,
          size: 16,
          color: QeranColors.goldDeep,
        ),
        QeranSpacing.hs8,
        Flexible(
          child: Text(
            labelKey.t(context),
            textAlign: TextAlign.start,
            style: QeranTypography.label.copyWith(
              color: QeranColors.wine,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
