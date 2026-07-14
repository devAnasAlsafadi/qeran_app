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

  /// HTTP status of the failing response when the exception carried one
  /// (raw path only). Optional / null by default — existing construction sites
  /// keep working; repos that map on transport status read it.
  final int? statusCode;

  const CodedServerFailure({
    required super.message,
    required this.errorCode,
    this.statusCode,
  });

  @override
  List<Object?> get props => [message, errorCode, statusCode];
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

// ─── Purchase / store failures (RevenueCat) ──────────────────────────────
// Typed outcomes of a store purchase, mapped from `PurchasesErrorCode` in
// `purchase_error_mapper.dart`. Kept here alongside the rest of the hierarchy.

/// The current platform can't complete a purchase — iOS is locked until App
/// Store products + offers are ready (Q-B). Defensive backstop; the primary
/// gate is the paywall UI.
class PlatformNotSupportedFailure extends Failure {
  const PlatformNotSupportedFailure({super.message = LocaleKeys.errors_generic});
}

/// The user dismissed the store purchase sheet. The UI treats this as a
/// silent, non-error outcome, so [message] is rarely surfaced.
class UserCancelledFailure extends Failure {
  const UserCancelledFailure({super.message = LocaleKeys.errors_generic});
}

/// The product is already owned / active for this account.
class AlreadyOwnedFailure extends Failure {
  const AlreadyOwnedFailure({
    super.message = LocaleKeys.subscriptions_purchase_already_subscribed,
  });
}

/// The store is unavailable, or a store / network problem occurred.
class StoreUnavailableFailure extends Failure {
  const StoreUnavailableFailure({
    super.message = LocaleKeys.subscriptions_purchase_store_unavailable,
  });
}

/// RevenueCat API credentials issue (misconfiguration) — distinct from the
/// backend [AuthFailure] (a user 401).
class InvalidCredentialsFailure extends Failure {
  const InvalidCredentialsFailure({super.message = LocaleKeys.errors_generic});
}

/// No store [Package] matched the requested product id in the current
/// offering (usually a dashboard / product-id mismatch).
class NotFoundFailure extends Failure {
  const NotFoundFailure({super.message = LocaleKeys.errors_generic});
}

/// Any other store purchase error. [errorCode] is the RC `PurchasesErrorCode`
/// name and [underlyingMessage] the raw SDK message — both for logging /
/// telemetry, while [message] stays a localized user-facing string.
class GenericPurchaseFailure extends Failure {
  final String errorCode;
  final String? underlyingMessage;

  const GenericPurchaseFailure({
    required this.errorCode,
    this.underlyingMessage,
    super.message = LocaleKeys.errors_generic,
  });

  @override
  List<Object?> get props => [message, errorCode, underlyingMessage];
}
