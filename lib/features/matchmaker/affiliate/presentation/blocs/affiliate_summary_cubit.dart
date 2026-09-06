import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';
import 'package:qeran/core/state/safe_emit.dart';

import '../../domain/failures/affiliate_failures.dart';
import '../../domain/usecases/get_affiliate_summary_usecase.dart';
import 'affiliate_summary_state.dart';

/// Screen-scoped controller for the affiliate dashboard header. Loads
/// `/affiliate/summary` once; the key distinction is that a not-enrolled
/// matchmaker (mapped to [AffiliateNotEnrolledFailure] in the repo) resolves to
/// a dedicated [AffiliateSummaryStatus.notEnrolled] state, while every real
/// failure resolves to the retryable [AffiliateSummaryStatus.error]. (The UI
/// for each state lands in a later sub-step.)
class AffiliateSummaryCubit extends Cubit<AffiliateSummaryState>
    with SafeEmit<AffiliateSummaryState> {
  final GetAffiliateSummaryUseCase _getSummary;

  AffiliateSummaryCubit({required GetAffiliateSummaryUseCase getSummary})
      : _getSummary = getSummary,
        super(const AffiliateSummaryState());

  Future<void> load() async {
    emit(state.copyWith(
      status: AffiliateSummaryStatus.loading,
      clearError: true,
    ));
    final result = await _getSummary();
    if (isClosed) return;
    result.fold(
      (failure) {
        if (failure is AffiliateNotEnrolledFailure) {
          AppLogger.info('AFFILIATE — not enrolled', tag: 'AFFILIATE');
          emit(state.copyWith(
            status: AffiliateSummaryStatus.notEnrolled,
            clearError: true,
          ));
          return;
        }
        AppLogger.warning(
          'AFFILIATE — summary failed raw="${failure.message}"',
          tag: 'AFFILIATE',
        );
        emit(state.copyWith(
          status: AffiliateSummaryStatus.error,
          errorKey: failure.message,
        ));
      },
      (summary) {
        // Built on the backend's word that the per-code figures add up, with
        // no manual check. This is that check, running on every load: a
        // mismatch means the stored account counters have drifted from the
        // referral rows, and it would otherwise surface only as a money figure
        // nobody could explain. Logged, never corrected — the app shows what
        // it is sent, and inventing a total here would hide the fault.
        if (!summary.codesReconcile) {
          AppLogger.warning(
            'AFFILIATE — codes do NOT reconcile with the account totals: '
            'used ${summary.codesUsedSum} vs ${summary.codeUsedCount}, '
            'earned ${summary.codesCommissionSum} vs ${summary.totalCommission}',
            tag: 'AFFILIATE',
          );
        }
        emit(state.copyWith(
          status: AffiliateSummaryStatus.loaded,
          summary: summary,
          clearError: true,
        ));
      },
    );
  }
}
