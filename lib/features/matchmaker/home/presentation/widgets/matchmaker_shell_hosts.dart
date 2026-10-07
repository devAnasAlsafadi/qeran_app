import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/di/injection_container.dart';
import '../../../../badges/presentation/blocs/badges_cubit.dart';
import '../../../../badges/presentation/widgets/badges_realtime_host.dart';
import '../../../../chat/domain/ports/chat_realtime_port.dart';
import '../../../../chat/presentation/widgets/chat_realtime_host.dart';
import '../../../dashboard/presentation/blocs/matchmaker_dashboard_cubit.dart';
import '../../../shared/domain/ports/matchmaker_realtime_port.dart';
import 'matchmaker_realtime_host.dart';

/// What her shell holds open above its tabs, so that no tab and no pushed
/// screen can take it down.
class MatchmakerShellHosts extends StatelessWidget {
  const MatchmakerShellHosts({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MatchmakerRealtimeHost(
      port: sl<MatchmakerRealtimePort>(),
      // Owns the `/hubs/chat` session for the matchmaker shell. Separate from
      // [MatchmakerRealtimePort] above: that one carries case/conversation
      // events, this one carries the chat hub the shared conversation screen
      // reads — and, from batch 18, the badge events for every tab. Held here
      // rather than by the pushed chat screen so leaving a conversation can no
      // longer take the badges' transport down with it.
      child: ChatRealtimeHost(
        port: sl<ChatRealtimePort>(),
        accessTokenProvider: sl<ChatAccessTokenProvider>(),
        // Turns that session into live counts: assigns what the hub sends,
        // and refetches whatever a dropped socket missed.
        child: BadgesRealtimeHost(
          port: sl<ChatRealtimePort>(),
          badges: sl<BadgesCubit>(),
          // Above the tabs, so both the Dashboard tab and the Users tab's
          // pending badge read the same stats.
          child: BlocProvider<MatchmakerDashboardCubit>(
            create: (_) => sl<MatchmakerDashboardCubit>()..load(),
            child: child,
          ),
        ),
      ),
    );
  }
}
