import 'package:equatable/equatable.dart';

import '../../domain/entities/affiliate_summary.dart';

/// Load status of the affiliate summary. [notEnrolled] is a first-class,
/// non-error outcome (backend 404): the matchmaker simply isn't in the program
/// yet, so the UI shows a dedicated informational state — NOT the retryable
/// [error] state (network / 500 / unexpected).
enum AffiliateSummaryStatus { initial, loading, loaded, notEnrolled, error }

class AffiliateSummaryState extends Equatable {
  final AffiliateSummaryStatus status;
  final AffiliateSummary? summary;

  /// Error text for [AffiliateSummaryStatus.error] — a locale key or server
  /// message, run through `.t(context)`. Null for the not-enrolled state.
  final String? errorKey;

  const AffiliateSummaryState({
    this.status = AffiliateSummaryStatus.initial,
    this.summary,
    this.errorKey,
  });

  AffiliateSummaryState copyWith({
    AffiliateSummaryStatus? status,
    AffiliateSummary? summary,
    String? errorKey,
    bool clearError = false,
  }) {
    return AffiliateSummaryState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorKey: clearError ? null : (errorKey ?? this.errorKey),
    );
  }

  @override
  List<Object?> get props => [status, summary, errorKey];
}
