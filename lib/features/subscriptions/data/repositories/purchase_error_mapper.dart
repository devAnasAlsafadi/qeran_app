import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:qeran/core/errors/errors.dart';

/// Maps a RevenueCat [PlatformException] to a typed [Failure] via
/// [PurchasesErrorHelper]. Branch on the error **code**, never the message.
Failure mapPurchaseError(PlatformException e) {
  final code = PurchasesErrorHelper.getErrorCode(e);
  switch (code) {
    case PurchasesErrorCode.purchaseCancelledError:
      return const UserCancelledFailure();
    case PurchasesErrorCode.productAlreadyPurchasedError:
      return const AlreadyOwnedFailure();
    case PurchasesErrorCode.storeProblemError:
    case PurchasesErrorCode.networkError:
    case PurchasesErrorCode.offlineConnectionError:
      return const StoreUnavailableFailure();
    case PurchasesErrorCode.invalidCredentialsError:
      return const InvalidCredentialsFailure();
    default:
      return GenericPurchaseFailure(
        errorCode: code.name,
        underlyingMessage: e.message,
      );
  }
}
