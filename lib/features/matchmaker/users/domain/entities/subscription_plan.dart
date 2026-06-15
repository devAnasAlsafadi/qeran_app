import 'package:equatable/equatable.dart';

/// One subscription plan from `GET /api/matchmaker/users/subscription-plans`.
///
/// Drives the dynamic plan-filter rail under the مشتركون tab — the rail is
/// generated from this list, never hardcoded, so a plan added from the
/// dashboard appears automatically.
///
/// [planId] is the STABLE key: filter the approved-subscribed list by it
/// (server-side `?planId=`) and match a subscriber's
/// `MatchmakerUserRow.subscriptionPlanId` against it — never the displayed
/// [nameAr] (which varies by locale).
///
/// The backend also sends `icon` + `color`, but we intentionally IGNORE both
/// (design decision): plans wear OUR wine/gold chip identity, distinguished by
/// name, not by the backend's raw colour/glyph.
class SubscriptionPlan extends Equatable {
  final int planId;
  final String nameAr;
  final String nameEn;
  final int subscriberCount;

  const SubscriptionPlan({
    required this.planId,
    required this.nameAr,
    required this.nameEn,
    required this.subscriberCount,
  });

  /// Plan name for the active locale (falls back to the other when one is
  /// empty), mirroring the row-card's bilingual-field convention.
  String name({required bool isArabic}) {
    final primary = isArabic ? nameAr : nameEn;
    if (primary.isNotEmpty) return primary;
    return isArabic ? nameEn : nameAr;
  }

  @override
  List<Object?> get props => [planId, nameAr, nameEn, subscriberCount];
}
