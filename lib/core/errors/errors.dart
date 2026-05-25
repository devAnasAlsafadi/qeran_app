import 'package:equatable/equatable.dart';
import 'package:qeran/generated/locale_keys.g.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure({required this.message});

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message});
}

class AuthFailure extends Failure {
  const AuthFailure({super.message = LocaleKeys.errors_unauthorized});
}

class OfflineFailure extends Failure {
  const OfflineFailure({super.message = LocaleKeys.errors_offline});
}
