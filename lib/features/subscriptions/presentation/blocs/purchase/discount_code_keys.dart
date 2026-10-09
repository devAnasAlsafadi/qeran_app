import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import '../../../data/error_codes.dart';

/// What the member reads when a discount code is refused (Phase 4 B3,
/// `03-api-contract.md` §12.5). A wrong, expired or used-up code says which;
/// a code the server couldn't apply (its own configuration) never says
/// "wrong code".
abstract final class DiscountCodeKeys {
  static const _byCode = {
    SubscriptionsErrorCodes.discountCodeInvalid:
        LocaleKeys.subscriptions_discount_code_wrong,
    SubscriptionsErrorCodes.discountCodeExpired:
        LocaleKeys.subscriptions_discount_code_expired,
    SubscriptionsErrorCodes.discountCodeExhausted:
        LocaleKeys.subscriptions_discount_code_used_up,
    SubscriptionsErrorCodes.discountProductUnknown:
        LocaleKeys.subscriptions_discount_code_unavailable,
    SubscriptionsErrorCodes.discountOfferUnavailable:
        LocaleKeys.subscriptions_discount_code_unavailable,
  };

  /// A `valid: false` answer: its code's key, or the long-standing "invalid
  /// or expired" when it named none (or one this map doesn't know).
  static String rejected(String? errorCode) =>
      _byCode[errorCode] ?? LocaleKeys.subscriptions_discount_code_invalid;

  /// A request that failed. The codes can also come as a `success: false`
  /// body or a non-2xx (both reach here as a `CodedServerFailure`); anything
  /// else — `VALIDATION_ERROR`, the network — is the generic error, never a
  /// verdict on the code.
  static String failed(Failure failure) => switch (failure) {
    CodedServerFailure(:final errorCode) when _byCode.containsKey(errorCode) =>
      _byCode[errorCode]!,
    _ => LocaleKeys.errors_generic,
  };
}
