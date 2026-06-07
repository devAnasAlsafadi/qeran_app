import 'package:equatable/equatable.dart';

import 'matchmaker_interest_user.dart';

/// A matchmaker interests page (`MatchmakerUserPageDto<T>`): the [user] header +
/// the tab [data] (a like activity, a match list, or an archive list).
class MatchmakerInterestPage<T> extends Equatable {
  final MatchmakerInterestUser user;
  final T data;

  const MatchmakerInterestPage({required this.user, required this.data});

  @override
  List<Object?> get props => [user, data];
}
