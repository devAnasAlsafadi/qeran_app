import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/errors/errors.dart';

/// Sentinel [GenericPurchaseFailure.errorCode] for a [PlatformException] whose
/// `code` isn't the numeric string RevenueCat's helper expects.
const String kUnknownPlatformExceptionCode = 'unknown_platform_exception';

/// Maps a RevenueCat [PlatformException] to a typed [Failure] via
/// [PurchasesErrorHelper]. Branch on the error **code**, never the message.
///
/// Everything except a user cancel is logged here rather than upstream: the
/// raw store detail lives on [PlatformException.details] and is dropped the
/// moment we return a [Failure], so this is the only place it can be recorded.
Failure mapPurchaseError(PlatformException e) {
  final code = _errorCodeOf(e);
  if (code == null) {
    _log(e, 'unparsable code');
    return GenericPurchaseFailure(
      errorCode: kUnknownPlatformExceptionCode,
      underlyingMessage: e.message,
    );
  }

  // A cancel is a normal user action, not a fault — never logged as an error.
  if (code != PurchasesErrorCode.purchaseCancelledError) {
    _log(e, code.name);
  }

  switch (code) {
    case PurchasesErrorCode.purchaseCancelledError:
      return const UserCancelledFailure();
    case PurchasesErrorCode.productAlreadyPurchasedError:
      return const AlreadyOwnedFailure();
    // Transient — retrying is genuinely worth it.
    case PurchasesErrorCode.networkError:
    case PurchasesErrorCode.offlineConnectionError:
      return const StoreUnavailableFailure();
    // NOT transient: billing unavailable / storefront can't transact. Split out
    // of the line above so the copy stops promising that a retry will help.
    case PurchasesErrorCode.storeProblemError:
      return const StorePurchaseBlockedFailure();
    // The product exists for us but not for this storefront.
    case PurchasesErrorCode.productNotAvailableForPurchaseError:
      return const NotFoundFailure();
    case PurchasesErrorCode.purchaseNotAllowedError:
      return const PurchaseNotAllowedFailure();
    case PurchasesErrorCode.configurationError:
      return const StoreConfigurationFailure();
    // Accepted but unconfirmed — may still complete, so it is not a failure.
    case PurchasesErrorCode.paymentPendingError:
      return const PaymentPendingFailure();
    case PurchasesErrorCode.invalidCredentialsError:
      return const InvalidCredentialsFailure();
    default:
      return GenericPurchaseFailure(
        errorCode: code.name,
        underlyingMessage: e.message,
      );
  }
}

/// [PurchasesErrorHelper.getErrorCode] runs `num.parse(e.code)`, which throws a
/// [FormatException] on a non-numeric code (a platform-channel error such as
/// `"channel-error"`). Unguarded that throw escapes the caller's
/// `on PlatformException` clause entirely — a sibling `catch` cannot catch an
/// exception raised inside a catch block — leaving the purchase with no state
/// emitted and the CTA spinning forever. Null here means "not a RevenueCat
/// code".
PurchasesErrorCode? _errorCodeOf(PlatformException e) {
  try {
    return PurchasesErrorHelper.getErrorCode(e);
  } on FormatException {
    return null;
  }
}

/// One diagnostic line per store failure. `details` is `dynamic` and only
/// carries the readable fields on the RevenueCat path, so it is read
/// defensively — a bad cast here would resurrect the swallowed-error problem
/// this function exists to prevent.
void _log(PlatformException e, String code) {
  final details = e.details;
  final map = details is Map ? details : const {};
  AppLogger.error(
    'Store purchase failed: code=$code raw=${e.code} '
    'readable=${map['readableErrorCode'] ?? '-'} '
    'message=${e.message ?? '-'} '
    'underlying=${map['underlyingErrorMessage'] ?? '-'}',
    tag: 'PAYMENTS',
  );
}
