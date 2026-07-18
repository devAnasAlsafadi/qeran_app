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

  /// True for the single free plan (`pricings[].price == 0`, no store product
  /// ids). Drives the free-tier CTA path (`POST /subscribe`) instead of a
  /// store purchase.
  final bool isFree;

  /// Backend plan tier — **0=Free, 1=Basic, 2=VIP** (Tariq's live contract).
  /// Identify plans by this, never by name. Nullable: absent on older/partial
  /// payloads — a null tier deliberately matches NONE of [isVipTier]/
  /// [isBasicTier] (the three are not treated as exhaustive; callers must not
  /// read "not VIP" as "Basic or Free").
  final int? tier;

  /// Dashboard-controlled display bullets (newline-separated), per locale.
  /// Nullable — when absent the UI falls back to the numeric checklist. Read
  /// via [featureBullets], never split at the call site.
  final String? featuresAr;
  final String? featuresEn;

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
    required this.isFree,
    this.tier,
    this.featuresAr,
    this.featuresEn,
    required this.features,
    required this.pricings,
  });

  /// Tier identification (see [tier]). Null tier → both false.
  bool get isVipTier => tier == 2;
  bool get isBasicTier => tier == 1;

  /// Backend display bullets for the plan card — the active-locale lines
  /// (trimmed, blanks dropped), falling back to the other locale, then to an
  /// empty list when neither is set (callers then show the numeric checklist).
  /// Backend-driven: nothing is fabricated here.
  List<String> featureBullets({required bool isArabic}) {
    final primary = _splitBullets(isArabic ? featuresAr : featuresEn);
    if (primary.isNotEmpty) return primary;
    return _splitBullets(isArabic ? featuresEn : featuresAr);
  }

  static List<String> _splitBullets(String? raw) {
    if (raw == null) return const [];
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList(growable: false);
  }

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
        isFree,
        tier,
        featuresAr,
        featuresEn,
        features,
        pricings,
      ];
}
