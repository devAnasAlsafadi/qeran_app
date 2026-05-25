import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/datasources/shared_pref_service.dart';
import '../../on_boarding_model.dart';

part 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final SharedPrefService _sharedPref;

  OnboardingCubit({required SharedPrefService sharedPref})
    : _sharedPref = sharedPref,
      super(const OnboardingIdle());

  /// Called by PageView.onPageChanged (manual swipe).
  void onPageChanged(int index) {
    if (state is OnboardingIdle) {
      emit((state as OnboardingIdle).copyWith(currentPage: index));
    }
  }

  /// Advance to the next page or finish if already on the last page.
  void nextPage() {
    if (state is! OnboardingIdle) return;
    final s = state as OnboardingIdle;
    if (!s.isLastPage) {
      emit(s.copyWith(currentPage: s.currentPage + 1));
    } else {
      _finish();
    }
  }

  /// Go back to the previous page (no-op on first page).
  void previousPage() {
    if (state is! OnboardingIdle) return;
    final s = state as OnboardingIdle;
    if (!s.isFirstPage) emit(s.copyWith(currentPage: s.currentPage - 1));
  }

  /// Skip the onboarding entirely and persist the flag.
  Future<void> skip() => _finish();

  Future<void> _finish() async {
    await _sharedPref.save<bool>(StorageKeys.seenOnboarding, true);
    emit(const OnboardingDone());
  }
}
