import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qeran/core/design_system/widgets/qeran_filter_chip_facet.dart';
import 'package:qeran/core/state/safe_emit.dart';

import '../../../../discovery/domain/entities/discovery_filter_selection.dart';
import '../../../../discovery/domain/filter_display_order.dart';
import '../../../../discovery/domain/filter_payload_builders.dart';
import '../../../../discovery/domain/filter_question_screening.dart';
import '../../../../discovery/domain/filter_selection_rules.dart';
import '../../domain/usecases/get_explore_filters_usecase.dart';
import 'matchmaker_explore_filter_state.dart';

/// Screen-scoped controller for the explore filter sheet. PARALLEL to
/// `DiscoveryFilterCubit` (mirrored, not reused — discovery is untouched).
/// Owns the in-progress selections and exposes [buildQuestionFilters]. Only
/// `QuestionFilters`-style questions are surfaced; ranges + unusable types are
/// dropped on load (search + gender are screen-level, handled in S4c).
class MatchmakerExploreFilterCubit
    extends Cubit<MatchmakerExploreFilterState> with SafeEmit<MatchmakerExploreFilterState> {
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
      (questions) {
        final screened = screenFilterQuestions(
          all: questions,
          logTag: 'MM-EXPLORE-FILTERS',
        );
        final usable = sortedFilterQuestions(screened.kept);
        nonSearchableLongLists(
          questions: usable,
          optionCountThreshold: kQeranSearchableFacetThreshold,
          logTag: 'MM-EXPLORE-FILTERS',
        );
        emit(MatchmakerExploreFilterLoaded(
          questions: usable,
          selections: collapseForbiddenMultiSelections(
            questions: usable,
            seeded: _initialSelections,
            logTag: 'MM-EXPLORE-FILTERS',
          ),
        ));
      },
    );
  }

  /// Sets a numeric range (age/height/weight) — mirrors discovery's slider.
  void setRange(int questionId, int min, int max) {
    final loaded = _loaded();
    if (loaded == null) return;
    final next = Map<int, DiscoveryFilterSelection>.from(loaded.selections);
    next[questionId] = RangeSelection(min: min, max: max);
    emit(loaded.copyWith(selections: next));
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
    // A SingleValueSelection has to seed the list, not be discarded. A sheet
    // reopened after an earlier single-select apply carries one, and starting
    // from empty made the first tap RE-ADD the value the matchmaker was trying
    // to clear — it looked selected, tapped, and stayed selected.
    final existing = switch (current) {
      MultiValueSelection(:final values) => List<String>.from(values),
      SingleValueSelection(:final value) => <String>[value],
      _ => <String>[],
    };
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
    emit(
      loaded.copyWith(
        selections: const {},
        resetVersion: loaded.resetVersion + 1,
      ),
    );
  }

  /// Current selections as `{questionId: [values]}` for the datasource.
  Map<int, List<String>> buildQuestionFilters() {
    final loaded = _loaded();
    if (loaded == null) return const {};
    return exploreQuestionFilters(
      questions: loaded.questions,
      selections: loaded.selections,
      logTag: 'MM-EXPLORE-FILTERS',
    );
  }

  /// The trimmed numeric range maps for the request — see [trimmedRangeEdges]
  /// for the trimming and guard rules, which are shared verbatim with the user
  /// app's payload builder.
  ({Map<int, double> from, Map<int, double> to}) buildRangeFilters() {
    final loaded = _loaded();
    if (loaded == null) return (from: const {}, to: const {});
    final from = <int, double>{};
    final to = <int, double>{};
    final byId = {for (final q in loaded.questions) q.id: q};
    loaded.selections.forEach((id, sel) {
      final question = byId[id];
      if (sel is! RangeSelection || question == null) return;
      final edges = trimmedRangeEdges(
        question: question,
        selection: sel,
        logTag: 'MM-EXPLORE-FILTERS',
      );
      if (edges.from != null) from[id] = edges.from!.toDouble();
      if (edges.to != null) to[id] = edges.to!.toDouble();
    });
    return (from: from, to: to);
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
