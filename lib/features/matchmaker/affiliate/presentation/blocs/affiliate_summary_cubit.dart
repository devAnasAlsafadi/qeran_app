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
      (summary) => emit(state.copyWith(
        status: AffiliateSummaryStatus.loaded,
        summary: summary,
        clearError: true,
      )),
    );
  }
}
