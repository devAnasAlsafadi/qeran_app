import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// Localized user-facing key for a purchase [Failure] — branch on the type,
/// not the message. [UserCancelledFailure] is intentionally absent: the cubit
/// treats a cancel as a benign non-error, not a message.
String purchaseFailureMessage(Failure failure) => switch (failure) {
      AlreadyOwnedFailure() =>
        LocaleKeys.subscriptions_purchase_already_subscribed,
      StoreUnavailableFailure() =>
        LocaleKeys.subscriptions_purchase_store_unavailable,
      StorePurchaseBlockedFailure() =>
        LocaleKeys.subscriptions_purchase_country_restricted,
      PurchaseNotAllowedFailure() =>
        LocaleKeys.subscriptions_purchase_not_allowed,
      StoreConfigurationFailure() =>
        LocaleKeys.subscriptions_purchase_config_error,
      PaymentPendingFailure() => LocaleKeys.subscriptions_purchase_pending,
      InvalidCredentialsFailure() =>
        LocaleKeys.subscriptions_purchase_login_required,
      NotFoundFailure() =>
        LocaleKeys.subscriptions_purchase_package_not_found,
      _ => LocaleKeys.errors_generic,
    };
