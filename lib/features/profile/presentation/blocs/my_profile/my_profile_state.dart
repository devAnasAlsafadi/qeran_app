import 'package:equatable/equatable.dart';

import '../../../domain/entities/my_profile.dart';

sealed class MyProfileState extends Equatable {
  const MyProfileState();

  @override
  List<Object?> get props => const [];
}

final class MyProfileInitial extends MyProfileState {
  const MyProfileInitial();
}

final class MyProfileLoading extends MyProfileState {
  final MyProfile? previous;
  const MyProfileLoading({this.previous});

  @override
  List<Object?> get props => [previous];
}

final class MyProfileLoaded extends MyProfileState {
  final MyProfile profile;
  const MyProfileLoaded(this.profile);

  @override
  List<Object?> get props => [profile];
}

final class MyProfileFailure extends MyProfileState {
  final String message;
  final MyProfile? previous;
  const MyProfileFailure({required this.message, this.previous});

  @override
  List<Object?> get props => [message, previous];
}
