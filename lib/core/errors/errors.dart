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

/// `ServerFailure` enriched with the backend's machine-readable `errorCode`,
/// so cubits can branch on a specific code (e.g. `INVALID_STATUS_TRANSITION`)
/// instead of matching the human message. Plain `is ServerFailure` sites keep
/// matching — this is a subtype, not a replacement.
class CodedServerFailure extends ServerFailure {
  final String? errorCode;

  const CodedServerFailure({required super.message, required this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
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
