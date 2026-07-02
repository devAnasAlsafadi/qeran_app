import 'package:equatable/equatable.dart';

/// Result of `POST /api/subscriptions/validate-code` (returned **raw**, no
/// envelope). On a valid code, [offerId] is the store offer to hand to
/// RevenueCat. The iOS-only quartet [signature]/[keyId]/[nonce]/[timestampMs]
/// is the StoreKit promotional-offer signature — all `null` on Android, or
/// when Apple signing isn't configured yet. [message] carries the Arabic
/// user-facing text when [valid] is false (or when the iOS signature is
/// unavailable on an otherwise-valid code).
class ValidateCodeResponse extends Equatable {
  final bool valid;
  final int discountPercent;
  final String? offerId;
  final String? signature;
  final String? keyId;
  final String? nonce;
  final int? timestampMs;
  final String? message;

  const ValidateCodeResponse({
    required this.valid,
    required this.discountPercent,
    required this.offerId,
    required this.signature,
    required this.keyId,
    required this.nonce,
    required this.timestampMs,
    required this.message,
  });

  /// True only when the full iOS StoreKit promotional-offer signature quartet
  /// is present — the precondition for signing an iOS discounted purchase.
  bool get hasIosSignature =>
      signature != null &&
      keyId != null &&
      nonce != null &&
      timestampMs != null;

  @override
  List<Object?> get props => [
        valid,
        discountPercent,
        offerId,
        signature,
        keyId,
        nonce,
        timestampMs,
        message,
      ];
}
