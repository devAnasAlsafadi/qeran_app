import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/app_logger.dart';

import '../../../../discovery/domain/entities/discovery_filter_question.dart';
import '../../../../discovery/domain/entities/discovery_filter_selection.dart';
import '../../../../discovery/domain/entities/filter_question_type.dart';
import '../../domain/usecases/get_explore_filters_usecase.dart';
import 'matchmaker_explore_filter_state.dart';

/// Converts the sheet's selections into the `{questionId: [values]}` map the
/// explore datasource turns into `QuestionFilters[id]=comma-joined`. Pure +
/// top-level so the screen (S4c) can convert a returned selection map without
/// holding the cubit. RANGE selections are intentionally ignored — ranges are
/// out of scope for explore (the sheet never surfaces them).
Map<int, List<String>> exploreQuestionFiltersFromSelections(
  Map<int, DiscoveryFilterSelection> selections,
) {
  final out = <int, List<String>>{};
  selections.forEach((id, selection) {
    switch (selection) {
      case SingleValueSelection(value: final v):
        if (v.isNotEmpty) out[id] = [v];
      case MultiValueSelection(values: final vs):
        final nonEmpty = vs.where((v) => v.isNotEmpty).toList();
        if (nonEmpty.isNotEmpty) out[id] = nonEmpty;
      case RangeSelection():
        break; // out of scope for explore
    }
  });
  return out;
}

/// Screen-scoped controller for the explore filter sheet. PARALLEL to
/// `DiscoveryFilterCubit` (mirrored, not reused — discovery is untouched).
/// Owns the in-progress selections and exposes [buildQuestionFilters]. Only
/// `QuestionFilters`-style questions are surfaced; ranges + unusable types are
/// dropped on load (search + gender are screen-level, handled in S4c).
class MatchmakerExploreFilterCubit
    extends Cubit<MatchmakerExploreFilterState> {
  final GetExploreFiltersUseCase _getFilters;
  final Map<int, DiscoveryFilterSelection> _initialSelections;

  MatchmakerExploreFilterCubit({
    required GetExploreFiltersUseCase getFilters,
    Map<int, DiscoveryFilterSelection> initialSelections = const {},
  })  : _getFilters = getFilters,
        _initialSelections = Map.unmodifiable(initialSelections),
        super(const MatchmakerExploreFilterInitial());

  Future<void> loadFilters() async {
    emit(const MatchmakerExploreFilterLoading());
    final result = await _getFilters();
    result.fold(
      (failure) => emit(MatchmakerExploreFilterFailure(failure.message)),
      (questions) => emit(MatchmakerExploreFilterLoaded(
        questions: _usableQuestions(questions),
        selections: Map.of(_initialSelections),
      )),
    );
  }

  /// Keeps the question types the matchmaker sheet renders: select / radio /
  /// checkbox / interests / text, PLUS date / height / weight as EXACT-match
  /// single values (Tariq's explore contract — not ranges; date sent as
  /// `yyyy-MM-dd`, height/weight as a numeric string). `unknown` is kept only
  /// when it has options (single-choice fallback). A question explicitly
  /// flagged `isRange` is still dropped — explore has no range UI (defensive;
  /// explore `/filters` never sets it).
  List<DiscoveryFilterQuestion> _usableQuestions(
    List<DiscoveryFilterQuestion> all,
  ) {
    final kept = <DiscoveryFilterQuestion>[];
    for (final q in all) {
      if (q.isRange) {
        AppLogger.warning(
          'skip explore filter id=${q.id} — range (no range UI in explore)',
          tag: 'MM-EXPLORE-FILTERS',
        );
        continue;
      }
      switch (q.type) {
        case FilterQuestionType.select:
        case FilterQuestionType.radio:
        case FilterQuestionType.checkbox:
        case FilterQuestionType.interests:
        case FilterQuestionType.text:
        case FilterQuestionType.date:
        case FilterQuestionType.height:
        case FilterQuestionType.weight:
          kept.add(q);
        case FilterQuestionType.unknown:
          if (q.options != null && q.options!.isNotEmpty) kept.add(q);
      }
    }
    return kept;
  }

  /// Sets a single-value question (select/radio/text). Empty clears it;
  /// re-tapping the active value toggles it off.
  void setSingleValue(int questionId, String value) {
    final loaded = _loaded();
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
    final loaded = _loaded();
    if (loaded == null) return;
    final next = Map<int, DiscoveryFilterSelection>.from(loaded.selections);
    final current = next[questionId];
    final existing = current is MultiValueSelection
        ? List<String>.from(current.values)
        : <String>[];
    existing.contains(value) ? existing.remove(value) : existing.add(value);
    if (existing.isEmpty) {
      next.remove(questionId);
    } else {
      next[questionId] = MultiValueSelection(existing);
    }
    emit(loaded.copyWith(selections: next));
  }

  void clearAll() {
    final loaded = _loaded();
    if (loaded == null) return;
    emit(loaded.copyWith(selections: const {}));
  }

  /// Current selections as `{questionId: [values]}` for the datasource.
  Map<int, List<String>> buildQuestionFilters() {
    final loaded = _loaded();
    if (loaded == null) return const {};
    return exploreQuestionFiltersFromSelections(loaded.selections);
  }

  /// Snapshot of the raw selections (so the screen can re-seed the sheet).
  Map<int, DiscoveryFilterSelection> currentSelections() {
    final loaded = _loaded();
    return loaded == null ? const {} : Map.of(loaded.selections);
  }

  MatchmakerExploreFilterLoaded? _loaded() {
    final s = state;
    return s is MatchmakerExploreFilterLoaded ? s : null;
  }
}
