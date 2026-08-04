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

/// The no-subscription daily view cap (`DAILY_VIEWS_EXCEEDED`). Carries the
/// [resetAt] instant (next UTC midnight) for the reset countdown. Not a
/// paywall — the UI shows a "come back tomorrow" state.
class DailyViewsExceededFailure extends Failure {
  final DateTime resetAt;

  const DailyViewsExceededFailure({
    required this.resetAt,
    super.message = LocaleKeys.errors_generic,
  });

  @override
  List<Object?> get props => [message, resetAt];
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

/// A transient store / network problem — worth retrying. Kept separate from
/// [StorePurchaseBlockedFailure], which is not transient at all.
class StoreUnavailableFailure extends Failure {
  const StoreUnavailableFailure({
    super.message = LocaleKeys.subscriptions_purchase_store_unavailable,
  });
}

/// The store refused to transact: billing unavailable, or the account's
/// storefront/country cannot buy this product. Split out of
/// [StoreUnavailableFailure] because retrying never fixes it, so the copy must
/// not promise that it will.
class StorePurchaseBlockedFailure extends Failure {
  const StorePurchaseBlockedFailure({
    super.message = LocaleKeys.subscriptions_purchase_country_restricted,
  });
}

/// Purchases are disallowed on this device or account — iOS Screen Time /
/// parental controls, or a restricted profile. The user can fix it themselves,
/// which is why it gets its own message.
class PurchaseNotAllowedFailure extends Failure {
  const PurchaseNotAllowedFailure({
    super.message = LocaleKeys.subscriptions_purchase_not_allowed,
  });
}

/// RevenueCat / store product setup is wrong. This one is OUR fault, so the
/// copy neither blames the user nor invites an endless retry.
class StoreConfigurationFailure extends Failure {
  const StoreConfigurationFailure({
    super.message = LocaleKeys.subscriptions_purchase_config_error,
  });
}

/// The payment was accepted but is awaiting approval (deferred payment, SCA
/// challenge, Ask-to-Buy). NOT a failed purchase — it may still complete, so it
/// must never be reported as an error.
class PaymentPendingFailure extends Failure {
  const PaymentPendingFailure({
    super.message = LocaleKeys.subscriptions_purchase_pending,
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
