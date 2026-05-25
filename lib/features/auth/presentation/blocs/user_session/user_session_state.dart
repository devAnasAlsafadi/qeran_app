import 'package:equatable/equatable.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';

sealed class UserSessionState extends Equatable {
  const UserSessionState();

  @override
  List<Object?> get props => const [];
}

final class UserSessionInitial extends UserSessionState {
  const UserSessionInitial();
}

final class UserSessionLoading extends UserSessionState {
  const UserSessionLoading();
}

final class UserSessionAuthenticated extends UserSessionState {
  final UserEntity user;
  const UserSessionAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

final class UserSessionUnauthenticated extends UserSessionState {
  const UserSessionUnauthenticated();
}
