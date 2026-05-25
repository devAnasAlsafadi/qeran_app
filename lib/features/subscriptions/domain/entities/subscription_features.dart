import 'package:equatable/equatable.dart';

/// Per-plan feature allowances ("how much the user gets while subscribed").
///
/// All four fields use the same convention:
/// `-1` means **unlimited** — render as "غير محدود", never as a count.
/// Any other non-negative integer is the per-period cap.
///
/// Helpers ([isUnlimited], [SubscriptionFeatures.unlimitedSentinel]) hide
/// the magic value so UI code never references `-1` directly.
class SubscriptionFeatures extends Equatable {
  /// Sentinel used by the backend for unlimited allowances on the
  /// **features** payload. Kept here so UI helpers don't reach into
  /// magic numbers.
  static const int unlimitedSentinel = -1;

  final int likesAllowed;
  final int seriousInterestsAllowed;
  final int photoExchangesAllowed;
  final int dailyProfileViewsAllowed;

  const SubscriptionFeatures({
    required this.likesAllowed,
    required this.seriousInterestsAllowed,
    required this.photoExchangesAllowed,
    required this.dailyProfileViewsAllowed,
  });

  /// True when [value] represents "غير محدود" on the **features** payload.
  static bool isUnlimited(int value) => value == unlimitedSentinel;

  @override
  List<Object?> get props => [
        likesAllowed,
        seriousInterestsAllowed,
        photoExchangesAllowed,
        dailyProfileViewsAllowed,
      ];
}
