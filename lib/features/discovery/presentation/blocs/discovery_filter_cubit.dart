import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/widgets/qeran_filter_chip_facet.dart';
import 'package:qeran/core/state/safe_emit.dart';

import '../../domain/entities/discovery_filter_selection.dart';
import '../../domain/filter_display_order.dart';
import '../../domain/filter_payload_builders.dart';
import '../../domain/filter_question_screening.dart';
import '../../domain/filter_selection_rules.dart';
import '../../domain/usecases/get_discovery_filters_usecase.dart';
import 'discovery_filter_state.dart';

/// Screen-scoped controller for the filter sheet.
///
/// Owns the in-progress selections while the sheet is open and produces
/// the backend-confirmed flat query map via [buildPayload]:
///
/// * Range types  → `RangeFrom[id]`, `RangeTo[id]`
/// * Single types → `QuestionFilters[id]`
/// * Multi types  → `QuestionFilters[id]` with comma-joined values
class DiscoveryFilterCubit extends Cubit<DiscoveryFilterState>
    with SafeEmit<DiscoveryFilterState> {
  final GetDiscoveryFiltersUseCase _getFilters;

  final Map<int, DiscoveryFilterSelection> _initialSelections;

  DiscoveryFilterCubit({
    required GetDiscoveryFiltersUseCase getFilters,
    Map<int, DiscoveryFilterSelection> initialSelections = const {},
  }) : _getFilters = getFilters,
       _initialSelections = Map.unmodifiable(initialSelections),
       super(const DiscoveryFilterInitial());

  Future<void> loadFilters() async {
    emit(const DiscoveryFilterLoading());
    final result = await _getFilters();
    result.fold((failure) => emit(DiscoveryFilterFailure(failure.message)), (
      questions,
    ) {
      final screened = screenFilterQuestions(
        all: questions,
        logTag: 'DISCOVERY_FILTERS',
      );
      final visible = sortedFilterQuestions(screened.kept);
      nonSearchableLongLists(
        questions: visible,
        optionCountThreshold: kQeranSearchableFacetThreshold,
        logTag: 'DISCOVERY_FILTERS',
      );
      emit(
        DiscoveryFilterLoaded(
          questions: visible,
          selections: collapseForbiddenMultiSelections(
            questions: visible,
            seeded: _initialSelections,
            logTag: 'DISCOVERY_FILTERS',
          ),
        ),
      );
    });
  }

  void setRange(int questionId, int min, int max) {
    final loaded = _requireLoaded();
    if (loaded == null) return;
    final next = Map<int, DiscoveryFilterSelection>.from(loaded.selections);
    next[questionId] = RangeSelection(min: min, max: max);
    emit(loaded.copyWith(selections: next));
  }

  /// Sets the selection for a single-value question (select/radio/text).
  ///
  /// * Empty [value] removes the selection (used by the text widget's
  ///   clear/empty state).
  /// * Tapping the active option of a select/radio clears it (toggle).
  void setSingleValue(int questionId, String value) {
    final loaded = _requireLoaded();
    if (loaded == null) return;
    final next = Map<int, DiscoveryFilterSelection>.from(loaded.selections);
    if (value.isEmpty) {
      next.remove(questionId);
    } else {
      final current = next[questionId];
      if (current is SingleValueSelection && current.value == value) {
        next.remove(questionId);
      } else {
        next[questionId] = SingleValueSelection(value);
      }
    }
    emit(loaded.copyWith(selections: next));
  }

  void toggleMultiValue(int questionId, String value) {
    final loaded = _requireLoaded();
    if (loaded == null) return;
    final next = Map<int, DiscoveryFilterSelection>.from(loaded.selections);
    final current = next[questionId];
    // A SingleValueSelection has to seed the list, not be discarded. A sheet
    // reopened after an earlier single-select apply carries one, and starting
    // from empty made the first tap RE-ADD the value the user was trying to
    // clear — it looked selected, tapped, and stayed selected.
    final existing = switch (current) {
      MultiValueSelection(:final values) => List<String>.from(values),
      SingleValueSelection(:final value) => <String>[value],
      _ => <String>[],
    };
    if (existing.contains(value)) {
      existing.remove(value);
    } else {
      existing.add(value);
    }
    if (existing.isEmpty) {
      next.remove(questionId);
    } else {
      next[questionId] = MultiValueSelection(existing);
    }
    emit(loaded.copyWith(selections: next));
  }

  void clearAll() {
    final loaded = _requireLoaded();
    if (loaded == null) return;
    emit(
      loaded.copyWith(
        selections: const {},
        resetVersion: loaded.resetVersion + 1,
      ),
    );
  }

  /// Flat query map for the request — see [buildDiscoveryFilterPayload] for the
  /// contract. Empty selections produce an empty map, which the caller treats
  /// as "clear all filters".
  Map<String, String> buildPayload() {
    final loaded = _requireLoaded();
    if (loaded == null) return const {};
    return buildDiscoveryFilterPayload(
      questions: loaded.questions,
      selections: loaded.selections,
      logTag: 'DISCOVERY_FILTERS',
    );
  }

  /// Snapshot of the current raw selections, so the opener can persist them and
  /// re-seed the sheet on reopen (mirrors the matchmaker explore filter).
  Map<int, DiscoveryFilterSelection> currentSelections() {
    final loaded = _requireLoaded();
    return loaded == null ? const {} : Map.of(loaded.selections);
  }

  DiscoveryFilterLoaded? _requireLoaded() {
    final s = state;
    return s is DiscoveryFilterLoaded ? s : null;
  }
}
