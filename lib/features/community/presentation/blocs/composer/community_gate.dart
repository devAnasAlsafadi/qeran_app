import '../../../../profile/presentation/blocs/profile_gate/profile_gate_state.dart';

/// A step a member owes before writing in Community, in the server's order
/// (contract §4): a real display name (D17), then the guidelines (D7). The
/// approval gate (D9) isn't one — a member not approved reads only.
enum CommunityGate { name, guidelines }

/// The first step [state] says is owed. A profile not known yet owes
/// nothing: the server stays the real gate and answers a send with the step
/// instead (S5).
CommunityGate? communityGateOf(ProfileGateState state) => switch (state) {
  ProfileGateResolved(isDefaultName: true) => CommunityGate.name,
  ProfileGateResolved(communityGuidelinesAccepted: false) =>
    CommunityGate.guidelines,
  _ => null,
};
