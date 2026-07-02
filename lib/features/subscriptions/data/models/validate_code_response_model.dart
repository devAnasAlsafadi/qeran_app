import '../../domain/entities/validate_code_response.dart';

/// Parses the **raw** `POST /api/subscriptions/validate-code` body. All fields
/// are camelCase; every field except [valid]/[discountPercent] is nullable.
/// [timestampMs] is epoch millis — parsed via `num` so a large 64-bit value
/// (or a JSON double) is tolerated.
class ValidateCodeResponseModel {
  final bool valid;
  final int discountPercent;
  final String? offerId;
  final String? signature;
  final String? keyId;
  final String? nonce;
  final int? timestampMs;
  final String? message;

  const ValidateCodeResponseModel({
    required this.valid,
    required this.discountPercent,
    required this.offerId,
    required this.signature,
    required this.keyId,
    required this.nonce,
    required this.timestampMs,
    required this.message,
  });

  factory ValidateCodeResponseModel.fromJson(Map<String, dynamic> json) {
    return ValidateCodeResponseModel(
      valid: json['valid'] as bool? ?? false,
      discountPercent: (json['discountPercent'] as num?)?.toInt() ?? 0,
      offerId: json['offerId'] as String?,
      signature: json['signature'] as String?,
      keyId: json['keyId'] as String?,
      nonce: json['nonce'] as String?,
      timestampMs: (json['timestampMs'] as num?)?.toInt(),
      message: json['message'] as String?,
    );
  }

  ValidateCodeResponse toEntity() => ValidateCodeResponse(
        valid: valid,
        discountPercent: discountPercent,
        offerId: offerId,
        signature: signature,
        keyId: keyId,
        nonce: nonce,
        timestampMs: timestampMs,
        message: message,
      );
}
