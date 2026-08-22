import '../../domain/entities/matchmaker_user_profile.dart';
import '../matchmaker_user_profile_args.dart';

/// Who the profile's "contact the responsible matchmaker" button should reach,
/// or null when it should not be drawn at all.
///
/// Kept out of the widget so the rule can be asserted without pumping the
/// profile screen, which pulls in the hero, the main card and the placement
/// renderer to decide one nullable value.
///
/// Two sources, deliberately. [navArg] carries what an explore row already
/// knew, so that path paints the button on the first frame; the fetched
/// [MatchmakerUserProfile.assignedMatchmaker] replaces it once the round trip
/// lands, and is the ONLY source for every other entry point — a chat, a deep
/// link, the router's bare-id path — none of which carry an arg.
ResponsibleMatchmakerContact? profileContact({
  required MatchmakerUserProfile profile,
  ResponsibleMatchmakerContact? navArg,
}) {
  // Mine already — "the responsible matchmaker" would be me.
  //
  // ⚠️ LOAD-BEARING. Do not remove this as a redundant flag check, and do not
  // "correct" it to match the backend's own advice — read this first.
  //
  // Backend batch 22 confirms `assignedMatchmaker` is populated identically
  // whoever is reading: it answers "who is responsible for this user", which
  // has nothing to do with the viewer. It is null in exactly one case, when
  // nobody is assigned. So the server will NEVER null it out for the
  // responsible matchmaker viewing her own user — this check is the only
  // thing standing between her and a button pointed at herself.
  //
  // That same batch recommends dropping this check, on the grounds that
  // hiding the button from the responsible matchmaker hides it from "the
  // person most entitled to it". That reasoning is about a different button.
  // Ours posts to `/api/matchmaker/colleagues/{id}/open-chat` — it opens a
  // COLLEAGUE conversation, for reaching the other matchmaker about a user
  // who is not yours. Follow the advice and the assigned matchmaker gets a
  // control that opens a colleague chat with her own id.
  if (profile.isAssignedToMe) return null;

  final fetched = profile.assignedMatchmaker;
  if (fetched == null) return navArg;

  return ResponsibleMatchmakerContact(
    id: fetched.id,
    name: fetched.name,
    profileImageUrl: fetched.imageUrl,
  );
}
