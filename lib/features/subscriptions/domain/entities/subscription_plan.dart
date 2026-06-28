import 'package:equatable/equatable.dart';

import 'subscription_features.dart';
import 'subscription_pricing.dart';

/// A dashboard-defined plan ("Gold", "Premium", …). Plans are dynamic —
/// names, colors, icons, features, pricings all come from the server,
/// so the UI must never hardcode any of them.
class SubscriptionPlan extends Equatable {
  final int id;
  final String nameAr;
  final String nameEn;
  final String? descriptionAr;
  final String? descriptionEn;

  /// Free-form: may be an emoji glyph (e.g. "💎") or a fully-qualified URL.
  /// UI detects which via [Uri.tryParse] + scheme check.
  final String icon;

  /// `#RRGGBB`. Validated and falls back to `QeranColors.wine` if malformed
  /// (see `PlanVisual.parseColor`).
  final String color;

  final int sortOrder;
  final bool isActive;

  /// "الأكثر طلباً" badge on the plan card (distinct from any pricing's
  /// own `isPopular`).
  final bool isPopular;

  final SubscriptionFeatures features;
  final List<SubscriptionPricing> pricings;

  const SubscriptionPlan({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.icon,
    required this.color,
    required this.sortOrder,
    required this.isActive,
    required this.isPopular,
    required this.features,
    required this.pricings,
  });

  /// Active pricings preserved in server `sortOrder`.
  List<SubscriptionPricing> get activePricings =>
      pricings.where((p) => p.isActive).toList();

  /// Locale-aware plan name: the active-locale field, falling back to the
  /// other when the primary is empty. The backend ships both; the UI must
  /// never hardcode one.
  String name({required bool isArabic}) {
    final primary = isArabic ? nameAr : nameEn;
    if (primary.isNotEmpty) return primary;
    return isArabic ? nameEn : nameAr;
  }

  @override
  List<Object?> get props => [
        id,
        nameAr,
        nameEn,
        descriptionAr,
        descriptionEn,
        icon,
        color,
        sortOrder,
        isActive,
        isPopular,
        features,
        pricings,
      ];
}
