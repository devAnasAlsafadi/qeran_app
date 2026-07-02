/// Request body for `POST /api/subscriptions/validate-code`.
///
/// [productId] is the platform store product id (`googleProductId` on Android,
/// `appleProductId` on iOS). [platform] is lowercase `"android"` or `"ios"` —
/// the backend enum is case-insensitive, but the doc's examples are lowercase
/// so we send lowercase.
class ValidateCodeRequest {
  final String code;
  final String productId;
  final String platform;

  const ValidateCodeRequest({
    required this.code,
    required this.productId,
    required this.platform,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'productId': productId,
        'platform': platform,
      };
}
