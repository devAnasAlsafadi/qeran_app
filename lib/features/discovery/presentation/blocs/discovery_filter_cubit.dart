import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/state/safe_emit.dart';
import 'package:qeran/core/app_logger.dart';

import '../../domain/entities/discovery_filter_question.dart';
import '../../domain/entities/discovery_filter_selection.dart';
import '../../domain/entities/filter_question_type.dart';
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
class DiscoveryFilterCubit extends Cubit<DiscoveryFilterState> with SafeEmit<DiscoveryFilterState> {
  final GetDiscoveryFiltersUseCase _getFilters;

  final Map<int, DiscoveryFilterSelection> _initialSelections;

  DiscoveryFilterCubit({
    required GetDiscoveryFiltersUseCase getFilters,
    Map<int, DiscoveryFilterSelection> initialSelections = const {},
  })  : _getFilters = getFilters,
        _initialSelections = Map.unmodifiable(initialSelections),
        super(const DiscoveryFilterInitial());

  Future<void> loadFilters() async {
    emit(const DiscoveryFilterLoading());
    final result = await _getFilters();
    result.fold(
      (failure) => emit(DiscoveryFilterFailure(failure.message)),
      (questions) {
        final visible = _filterOutUnusable(questions);
        emit(DiscoveryFilterLoaded(
          questions: visible,
          selections: Map.of(_initialSelections),
        ));
      },
    );
  }

  /// Drops questions the renderer has no safe way to display.
  ///
  /// * `unknown` + no options → no way to render a control.
  /// * `height` / `weight` / `date` with `isRange == false` → these
  ///   types are expected to be ranges per backend contract; if the
  ///   flag is missing we can't fall back to a single-value control.
  List<DiscoveryFilterQuestion> _filterOutUnusable(
    List<DiscoveryFilterQuestion> all,
  ) {
    final kept = <DiscoveryFilterQuestion>[];
    for (final q in all) {
      if (q.isRange) {
        kept.add(q);
        continue;
      }
      switch (q.type) {
        case FilterQuestionType.select:
        case FilterQuestionType.radio:
        case FilterQuestionType.checkbox:
        case FilterQuestionType.interests:
        case FilterQuestionType.text:
          kept.add(q);
        case FilterQuestionType.unknown:
          if (q.options != null && q.options!.isNotEmpty) {
            kept.add(q);
          } else {
            AppLogger.warning(
              'skip filter id=${q.id} — unknown type, no options',
              tag: 'DISCOVERY_FILTERS',
            );
          }
        case FilterQuestionType.height:
        case FilterQuestionType.weight:
        case FilterQuestionType.date:
          AppLogger.warning(
            'skip filter id=${q.id} — ${q.type.name} sent with '
            'isRange=false (expected true)',
            tag: 'DISCOVERY_FILTERS',
          );
      }
    }
    return kept;
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
    final existing = current is MultiValueSelection
        ? List<String>.from(current.values)
        : <String>[];
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
    emit(loaded.copyWith(selections: const {}));
  }

  /// Flat query map keyed to the backend's confirmed contract:
  ///
  /// ```
  /// RangeFrom[<id>] = "<min>"
  /// RangeTo[<id>]   = "<max>"
  /// QuestionFilters[<id>] = "<value>"
  /// QuestionFilters[<id>] = "<v1>,<v2>,<v3>"
  /// ```
  ///
  /// Empty selections produce an empty map — the caller treats that as
  /// "clear all filters" and calls `DiscoveryCubit.applyFilters(null)`.
  Map<String, String> buildPayload() {
    final loaded = _requireLoaded();
    if (loaded == null) return const {};
    final payload = <String, String>{};
    loaded.selections.forEach((id, selection) {
      switch (selection) {
        case RangeSelection(min: final lo, max: final hi):
          payload['RangeFrom[$id]'] = lo.toString();
          payload['RangeTo[$id]'] = hi.toString();
        case SingleValueSelection(value: final v):
          if (v.isNotEmpty) payload['QuestionFilters[$id]'] = v;
        case MultiValueSelection(values: final vs):
          if (vs.isNotEmpty) {
            payload['QuestionFilters[$id]'] = vs.join(',');
          }
      }
    });
    return payload;
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
