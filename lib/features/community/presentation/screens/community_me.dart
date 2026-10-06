import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/blocs/user_session/user_session_cubit.dart';
import '../../../auth/presentation/blocs/user_session/user_session_state.dart';
import '../../../profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import '../../../profile/presentation/blocs/profile_gate/profile_gate_state.dart';
import '../../domain/entities/community_author.dart';
import '../../domain/entities/community_viewer.dart';

/// The viewer as the author of what they send, for its row until the
/// server's copy replaces it (D5): a member's display name from the profile
/// — or the session's while it loads; a matchmaker's from the session, as
/// the member's profile isn't hers.
CommunityAuthor communityMe(BuildContext context, CommunityViewer viewer) {
  final user = switch (_read<UserSessionCubit>(context)?.state) {
    UserSessionAuthenticated(:final user) => user,
    _ => null,
  };
  final name = viewer == CommunityViewer.member ? _profileName(context) : null;
  return CommunityAuthor(
    id: user?.id ?? '',
    displayName: name ?? user?.name ?? '',
    isMatchmaker: viewer == CommunityViewer.matchmaker,
  );
}

String? _profileName(BuildContext context) =>
    switch (_read<ProfileGateCubit>(context)?.state) {
      ProfileGateResolved(:final name) => name,
      _ => null,
    };

/// [T] when it's in scope; both live at the app's root.
T? _read<T>(BuildContext context) {
  try {
    return context.read<T>();
  } catch (_) {
    return null;
  }
}
