import 'package:equatable/equatable.dart';

/// One purchase option for a [SubscriptionPlan] — e.g. "month / 3 months /
/// year". `id` is the only key the mobile sends to `/subscribe` —
/// **never** use `planId`.
class SubscriptionPricing extends Equatable {
  final int id;
  final int planId;
  final int durationDays;

  /// Display label in the requested locale. May be null if the dashboard
  /// hasn't filled it; UI must fall back to "$durationDays يوم".
  final String? labelAr;
  final String? labelEn;

  final double price;

  /// MSRP before promotional discount. Render strike-through **only** when
  /// non-null AND strictly greater than [price].
  final double? originalPrice;

  /// Promotional discount percentage baked into [price]. Render the badge
  /// **only** when `> 0`.
  final int discountPercent;

  /// Already-computed monthly equivalent of [price] for the user-friendly
  /// "X ر.س/شهر" subtitle. Server-supplied — no client math.
  final double monthlyEquivalent;

  final int sortOrder;
  final bool isActive;

  /// "الأكثر اختياراً" badge on the pricing chip (distinct from the plan's
  /// own `isPopular` which renders "الأكثر طلباً" on the card).
  final bool isPopular;

  const SubscriptionPricing({
    required this.id,
    required this.planId,
    required this.durationDays,
    required this.labelAr,
    required this.labelEn,
    required this.price,
    required this.originalPrice,
    required this.discountPercent,
    required this.monthlyEquivalent,
    required this.sortOrder,
    required this.isActive,
    required this.isPopular,
  });

  /// True when [originalPrice] should be rendered struck-through next to
  /// [price]. Centralised so the rule lives in one place.
  bool get hasStrikethroughOriginal =>
      originalPrice != null && originalPrice! > price;

  /// True when the "خصم %" pill should be rendered. Centralised likewise.
  bool get hasDiscountBadge => discountPercent > 0;

  /// Locale-aware duration label: the active-locale field, falling back to the
  /// other when empty. Returns null when neither is set — callers then fall
  /// back to the "{days} days" string.
  String? label({required bool isArabic}) {
    final primary = isArabic ? labelAr : labelEn;
    if (primary != null && primary.isNotEmpty) return primary;
    final other = isArabic ? labelEn : labelAr;
    if (other != null && other.isNotEmpty) return other;
    return null;
  }

  @override
  List<Object?> get props => [
        id,
        planId,
        durationDays,
        labelAr,
        labelEn,
        price,
        originalPrice,
        discountPercent,
        monthlyEquivalent,
        sortOrder,
        isActive,
        isPopular,
      ];
}
