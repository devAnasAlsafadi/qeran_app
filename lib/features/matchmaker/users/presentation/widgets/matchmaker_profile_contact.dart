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
  // Mine already — "the responsible matchmaker" would be me. Checked here
  // rather than trusting the server to null the object for this case.
  if (profile.isAssignedToMe) return null;

  final fetched = profile.assignedMatchmaker;
  if (fetched == null) return navArg;

  return ResponsibleMatchmakerContact(
    id: fetched.id,
    name: fetched.name,
    profileImageUrl: fetched.imageUrl,
  );
}
