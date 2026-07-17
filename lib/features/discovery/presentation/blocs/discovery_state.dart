import 'package:equatable/equatable.dart';

import '../../domain/entities/discovery_profile.dart';

/// Typed projection of the last failed Like attempt.
///
/// The cubit stores this on the loaded state so the UI listener can
/// dispatch the right surface — paywall sheet vs transient toast vs
/// generic error — without re-classifying the raw server message at
/// the widget level. `null` means no current failure (the action either
/// succeeded or none has been attempted since the last clear).
enum LikeFailureKind {
  /// Subscription required or like quota exhausted.
  paywall,

  /// `يوجد طلب قائم بالفعل بينكما` — like already exists between the
  /// two users.
  alreadyPending,

  /// `لا يمكن إرسال إعجاب لشخص من نفس الجنس` — backend's matchmaking
  /// rule rejected the like.
  genderMismatch,

  /// `المستخدم غير موجود أو غير مرئي` — target user was removed or
  /// hid their profile.
  userUnavailable,

  /// Transport-level failure (network, timeout, parse) OR an
  /// unrecognised server message. UI shows a generic error toast.
  network,
}

sealed class DiscoveryState extends Equatable {
  const DiscoveryState();

  @override
  List<Object?> get props => const [];
}

final class DiscoveryInitial extends DiscoveryState {
  const DiscoveryInitial();
}

final class DiscoveryLoading extends DiscoveryState {
  const DiscoveryLoading();
}

/// Initial-page fetch failed. The UI should surface a retry button.
/// Prefetch failures are NOT modeled here — see [DiscoveryLoaded.prefetchError].
final class DiscoveryFailure extends DiscoveryState {
  final String message;
  const DiscoveryFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Active deck state. Stays here for the entire session once page 1
/// resolves, even when the deck is empty or exhausted (the UI branches
/// on `isEmpty` / `isExhausted`).
final class DiscoveryLoaded extends DiscoveryState {
  final List<DiscoveryProfile> profiles;
  final int currentIndex;
  final int currentPage;
  final int totalPages;
  final bool isPrefetching;

  /// Raw server / localized message for the most recent like/pass
  /// failure. UI consumes it as a one-shot snackbar via `BlocListener`.
  /// Cleared when the next action succeeds or `undo` rewinds.
  ///
  /// Kept around alongside [actionFailureKind] for two reasons:
  /// (1) backwards-compat with existing tests, and (2) the raw server
  /// message is useful in logs even when the kind already drives the UI.
  final String? actionError;

  /// Typed projection of [actionError] — drives which UI surface fires
  /// (paywall vs toast vs generic error). `null` when no failure is
  /// active. Set/cleared in lockstep with [actionError].
  final LikeFailureKind? actionFailureKind;

  /// Bumped every time the failure transitions from null to a value.
  /// Lets the listener detect consecutive failures with the same kind
  /// (Equatable would otherwise dedupe them).
  final int actionErrorVersion;

  /// Last prefetch's failure message (if any). Non-fatal — the deck
  /// keeps working with the cards already loaded. UI may show a small
  /// banner with a retry button.
  final String? prefetchError;

  const DiscoveryLoaded({
    required this.profiles,
    required this.currentIndex,
    required this.currentPage,
    required this.totalPages,
    this.isPrefetching = false,
    this.actionError,
    this.actionFailureKind,
    this.actionErrorVersion = 0,
    this.prefetchError,
  });

  bool get isEmpty => profiles.isEmpty;
  bool get isExhausted => currentIndex >= profiles.length;
  bool get hasMore => currentPage < totalPages;
  DiscoveryProfile? get current =>
      isExhausted ? null : profiles[currentIndex];

  DiscoveryProfile? get next =>
      currentIndex + 1 < profiles.length ? profiles[currentIndex + 1] : null;

  /// Copies the loaded state with selective overrides.
  ///
  /// `resetActionError` clears BOTH [actionError] and [actionFailureKind]
  /// — they're always set and cleared together.
  /// `resetPrefetchError` forces [prefetchError] to `null`.
  DiscoveryLoaded copyWith({
    List<DiscoveryProfile>? profiles,
    int? currentIndex,
    int? currentPage,
    int? totalPages,
    bool? isPrefetching,
    String? actionError,
    LikeFailureKind? actionFailureKind,
    int? actionErrorVersion,
    String? prefetchError,
    bool resetActionError = false,
    bool resetPrefetchError = false,
  }) {
    return DiscoveryLoaded(
      profiles: profiles ?? this.profiles,
      currentIndex: currentIndex ?? this.currentIndex,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isPrefetching: isPrefetching ?? this.isPrefetching,
      actionError:
          resetActionError ? null : (actionError ?? this.actionError),
      actionFailureKind: resetActionError
          ? null
          : (actionFailureKind ?? this.actionFailureKind),
      actionErrorVersion: actionErrorVersion ?? this.actionErrorVersion,
      prefetchError:
          resetPrefetchError ? null : (prefetchError ?? this.prefetchError),
    );
  }

  @override
  List<Object?> get props => [
        profiles,
        currentIndex,
        currentPage,
        totalPages,
        isPrefetching,
        actionError,
        actionFailureKind,
        actionErrorVersion,
        prefetchError,
      ];

  /// Concise one-line summary for logs (BlocObserver dumps `$change`).
  /// Deliberately omits the `profiles` payload — the default Equatable
  /// `toString` prints every prop, flooding the console with the full
  /// profile list on every state change. Only `toString` is overridden;
  /// `props` (equality/rebuild logic) is untouched.
  @override
  String toString() =>
      'DiscoveryLoaded(len: ${profiles.length}, idx: $currentIndex, '
      'page: $currentPage/$totalPages, prefetching: $isPrefetching'
      '${actionFailureKind != null ? ', fail: ${actionFailureKind!.name}#$actionErrorVersion' : ''}'
      '${prefetchError != null ? ', prefetchErr' : ''})';
}
