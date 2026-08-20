import 'package:equatable/equatable.dart';

import '../../domain/entities/discovery_empty_reason.dart';
import '../../domain/entities/discovery_profile.dart';
import 'discovery_reset_notice.dart';
import 'like_failure_kind.dart';

export 'discovery_reset_notice.dart';
export 'like_failure_kind.dart';

/// [DiscoveryLoaded] lives in its own file because it carries the whole deck's
/// working state and had outgrown the rest of the hierarchy. It is a `part`
/// rather than a separate library: a `sealed` supertype requires every subtype
/// in the SAME library, so a plain import would break exhaustive switching on
/// [DiscoveryState].
part 'discovery_loaded_state.dart';

/// The terminal-state signals sit apart from the data they read, because they
/// are the subject of the empty-deck branching rather than more deck state.
part 'discovery_terminal_signals.dart';

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

/// The no-subscription daily view cap was hit (`DAILY_VIEWS_EXCEEDED`). A
/// full-screen "come back tomorrow" state — NOT a paywall. [resetAt] drives the
/// reset countdown. Only ever emitted because the server returned the code
/// (no client-side cap counting).
final class DiscoveryDailyLimit extends DiscoveryState {
  final DateTime resetAt;
  const DiscoveryDailyLimit(this.resetAt);

  @override
  List<Object?> get props => [resetAt];
}
