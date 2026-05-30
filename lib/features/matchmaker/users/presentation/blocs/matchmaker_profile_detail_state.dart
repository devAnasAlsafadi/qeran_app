import 'package:equatable/equatable.dart';

import '../../domain/entities/matchmaker_user_profile.dart';

sealed class MatchmakerProfileDetailState extends Equatable {
  const MatchmakerProfileDetailState();

  @override
  List<Object?> get props => [];
}

class MatchmakerProfileDetailInitial extends MatchmakerProfileDetailState {
  const MatchmakerProfileDetailInitial();
}

class MatchmakerProfileDetailLoading extends MatchmakerProfileDetailState {
  const MatchmakerProfileDetailLoading();
}

class MatchmakerProfileDetailLoaded extends MatchmakerProfileDetailState {
  final MatchmakerUserProfile profile;
  const MatchmakerProfileDetailLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

class MatchmakerProfileDetailError extends MatchmakerProfileDetailState {
  /// Locale key or ready Arabic — run through `.t(context)` in the UI.
  final String message;
  const MatchmakerProfileDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
