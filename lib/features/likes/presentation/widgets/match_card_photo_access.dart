import 'package:flutter/material.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/extensions/localization_extension.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../domain/entities/match_card.dart';
import '../../domain/entities/match_case_stage.dart';
import '../../domain/entities/match_journey_outcome.dart';
import 'match_card_header.dart';

/// Whether a stage-1 card may still open the other member's photos, and what
/// it says when it may not.
///
/// ⚠️ This is the UX half of a boundary the CLIENT does not own. The bytes are
/// the server's to refuse — the protected image URL answers 403 and
/// `PhotoViewCubit.markImageAccessConsumed` locks on it — and the unblurred
/// URL is already sitting in the member's `/api/matches` payload before any
/// of this runs. Hiding a control is not access control, and nothing here
/// should ever be read as though it were.
///
/// It is still worth doing on its own terms, and for the reason the ended
/// countdown chip was gated client-side rather than left to the server: a
/// card offering an action the case no longer supports is wrong whatever the
/// server would answer, and the two agreeing is what stops a member being
/// invited into a refusal.
class MatchCardPhotoAccess {
  const MatchCardPhotoAccess._({
    required this.canOpen,
    required this.wasViewed,
  });

  /// The reveal is live: the gallery may be opened, and the avatar may be
  /// tapped to reach it.
  final bool canOpen;

  /// The one view was spent while the case was still running.
  final bool wasViewed;

  /// Both fall to false together on a case that has stopped — see
  /// [_caseIsRunning]. That is not a shortcut: the two are the only ways this
  /// card mentions photos at all, and an over case has nothing to say about
  /// them in either direction.
  static MatchCardPhotoAccess resolve(
    MatchCard card, {
    required VoidCallback? onOpen,
  }) {
    if (!_caseIsRunning(card)) {
      return const MatchCardPhotoAccess._(canOpen: false, wasViewed: false);
    }
    return MatchCardPhotoAccess._(
      // `isBlurred` is sticky once the window is spent, so the server's own
      // flags are what say whether the one view is still there. The card
      // never decides this for itself.
      canOpen: onOpen != null && card.images.any((image) => !image.isBlurred),
      wasViewed:
          card.images.isNotEmpty &&
          card.images.every((image) => image.isBlurred),
    );
  }

  /// A case still in motion — the only kind whose photos are anyone's
  /// business.
  ///
  /// Two clauses, and they cover opposite endings on purpose:
  ///   • [matchJourneyHasEnded] — cancelled, failed, or a declined formal
  ///     step. The owner's rule is that ending a case revokes photo access
  ///     immediately, even where both members had already agreed to the
  ///     exchange and neither had looked yet.
  ///   • [MatchCaseStage.marriageCompleted] — the SUCCESS ending, which
  ///     `matchJourneyHasEnded` deliberately excludes so that a wedding never
  ///     draws as a failure. It is excluded from photo access all the same:
  ///     the journey is complete and the photos stopped being the subject.
  ///
  /// The order of the two does not matter here, and that is worth saying
  /// because elsewhere it does: `MatchJourneyStep` resolves the contradictory
  /// card — a marriage stage arriving with a cancelled status — by letting
  /// the marriage win. Both clauses reach the same answer here, so the
  /// contradiction cannot make this function disagree with that one.
  static bool _caseIsRunning(MatchCard card) =>
      !matchJourneyHasEnded(card) &&
      card.caseStage != MatchCaseStage.marriageCompleted;
}

/// «تمت المشاهدة» — the one view, spent.
///
/// A STATUS, never a control. It stands in the slot the reveal button
/// vacates, because that is where the member last saw something about
/// photos and where they will look again; a card that simply loses the row
/// reads as though the photos went missing rather than as though the view
/// was used.
///
/// Muted rather than wine or gold: nothing here is an invitation, and the
/// stage's own status line above is still the card's live sentence.
///
/// Built from [MatchCardStatusLine] rather than a second icon-plus-text row,
/// so the two lines a card can carry about its own state are the same
/// construction at the same weight.
class MatchCardPhotosViewed extends StatelessWidget {
  const MatchCardPhotosViewed({super.key});

  @override
  Widget build(BuildContext context) {
    return MatchCardStatusLine(
      icon: Icons.visibility_off_outlined,
      text: LocaleKeys.likes_matches_photo_view_done.t(context),
      color: QeranColors.inkMuted,
    );
  }
}
