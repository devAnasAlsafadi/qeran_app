import '../../domain/entities/discount_validation.dart';

class DiscountValidationModel {
  final bool isValid;
  final double discountRate;
  final double originalPrice;
  final double finalPrice;

  const DiscountValidationModel({
    required this.isValid,
    required this.discountRate,
    required this.originalPrice,
    required this.finalPrice,
  });

  factory DiscountValidationModel.fromJson(Map<String, dynamic> json) {
    return DiscountValidationModel(
      isValid: json['isValid'] as bool? ?? false,
      discountRate: ((json['discountRate'] as num?) ?? 0).toDouble(),
      originalPrice: ((json['originalPrice'] as num?) ?? 0).toDouble(),
      finalPrice: ((json['finalPrice'] as num?) ?? 0).toDouble(),
    );
  }

  DiscountValidation toEntity() => DiscountValidation(
        isValid: isValid,
        discountRate: discountRate,
        originalPrice: originalPrice,
        finalPrice: finalPrice,
      );
}
