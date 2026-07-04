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

  /// Canonical cross-store product id for this pricing period (backend
  /// `storeProductId`) — the primary key for RevenueCat package lookup. The
  /// mapping is period-level, not plan-level (a plan may hold several priced
  /// periods, each its own product). `null` for a period not linked to the
  /// store (e.g. the free plan).
  final String? storeProductId;

  /// Platform-specific fallbacks used when [storeProductId] is absent (the
  /// stores may diverge). Prefer [productId], which resolves the canonical id
  /// first, then the platform id.
  final String? appleProductId;
  final String? googleProductId;

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
    required this.storeProductId,
    required this.appleProductId,
    required this.googleProductId,
  });

  /// True when [originalPrice] should be rendered struck-through next to
  /// [price]. Centralised so the rule lives in one place.
  bool get hasStrikethroughOriginal =>
      originalPrice != null && originalPrice! > price;

  /// True when the "خصم %" pill should be rendered. Centralised likewise.
  bool get hasDiscountBadge => discountPercent > 0;

  /// The store product id used for RevenueCat package lookup. Prefers the
  /// canonical cross-store [storeProductId]; falls back to the platform id
  /// ([appleProductId] on iOS, [googleProductId] elsewhere) when it's absent.
  /// Null when this pricing isn't store-linked (e.g. the free plan).
  String? productId({required bool isIOS}) {
    final canonical = storeProductId;
    if (canonical != null && canonical.isNotEmpty) return canonical;
    return isIOS ? appleProductId : googleProductId;
  }

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
        storeProductId,
        appleProductId,
        googleProductId,
      ];
}
