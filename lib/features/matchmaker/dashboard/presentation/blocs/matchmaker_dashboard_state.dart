import 'package:equatable/equatable.dart';

import '../../domain/entities/matchmaker_dashboard_stats.dart';

sealed class MatchmakerDashboardState extends Equatable {
  const MatchmakerDashboardState();

  @override
  List<Object?> get props => [];
}

class MatchmakerDashboardInitial extends MatchmakerDashboardState {
  const MatchmakerDashboardInitial();
}

class MatchmakerDashboardLoading extends MatchmakerDashboardState {
  const MatchmakerDashboardLoading();
}

class MatchmakerDashboardLoaded extends MatchmakerDashboardState {
  final MatchmakerDashboardStats stats;

  /// True while a pull-to-refresh round-trip is in flight; the previous
  /// cards stay visible underneath the refresh indicator.
  final bool isRefreshing;

  const MatchmakerDashboardLoaded(this.stats, {this.isRefreshing = false});

  MatchmakerDashboardLoaded copyWith({
    MatchmakerDashboardStats? stats,
    bool? isRefreshing,
  }) =>
      MatchmakerDashboardLoaded(
        stats ?? this.stats,
        isRefreshing: isRefreshing ?? this.isRefreshing,
      );

  @override
  List<Object?> get props => [stats, isRefreshing];
}

class MatchmakerDashboardError extends MatchmakerDashboardState {
  final String message;
  const MatchmakerDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
