import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_option.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_question.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_selection.dart';
import 'package:qeran/features/discovery/domain/entities/filter_question_type.dart';
import 'package:qeran/features/discovery/domain/filter_payload_builders.dart';
import 'package:qeran/features/matchmaker/explore/domain/usecases/get_explore_filters_usecase.dart';
import 'package:qeran/features/matchmaker/explore/presentation/blocs/matchmaker_explore_filter_cubit.dart';
import 'package:qeran/features/matchmaker/explore/presentation/blocs/matchmaker_explore_filter_state.dart';

/// Mirrors `discovery_filter_cubit_test.dart` where the behaviour overlaps —
/// the two cubits are deliberately duplicated rather than shared, so they need
/// parallel coverage or they drift.
///
/// The matchmaker's payload is SPLIT, unlike discovery's single `buildPayload()`:
/// `exploreQuestionFiltersFromSelections` for the facets and `buildRangeFilters`
/// for the trimmed numeric edges.
class _MockGetFilters extends Mock implements GetExploreFiltersUseCase {}

DiscoveryFilterQuestion _q({
  required int id,
  required FilterQuestionType type,
  bool isRange = false,
  List<DiscoveryFilterOption>? options,
  int? minValue,
  int? maxValue,
  bool? isMultiSelect,
  int? displayPriority,
}) => DiscoveryFilterQuestion(
  id: id,
  label: 'Question $id',
  type: type,
  isRange: isRange,
  minValue: minValue,
  maxValue: maxValue,
  options: options,
  isMultiSelect: isMultiSelect,
  displayPriority: displayPriority,
);

List<DiscoveryFilterOption> _opts(List<String> values) => values
    .map((v) => DiscoveryFilterOption(value: v, display: v))
    .toList();

void main() {
  late _MockGetFilters getFilters;
  late MatchmakerExploreFilterCubit cubit;

  setUp(() {
    getFilters = _MockGetFilters();
    cubit = MatchmakerExploreFilterCubit(getFilters: getFilters);
    addTearDown(cubit.close);
  });

  Future<void> loadWith(List<DiscoveryFilterQuestion> qs) async {
    when(() => getFilters()).thenAnswer((_) async => Right(qs));
    await cubit.loadFilters();
  }

  MatchmakerExploreFilterLoaded loaded() =>
      cubit.state as MatchmakerExploreFilterLoaded;

  group('loadFilters', () {
    test('emits Failure on Left', () async {
      when(() => getFilters()).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'errors.generic')),
      );

      await cubit.loadFilters();

      expect(cubit.state, isA<MatchmakerExploreFilterFailure>());
      expect(
        (cubit.state as MatchmakerExploreFilterFailure).message,
        'errors.generic',
      );
    });

    test('keeps select / radio / checkbox / interests / text', () async {
      await loadWith([
        _q(id: 1, type: FilterQuestionType.select, options: _opts(['a'])),
        _q(id: 2, type: FilterQuestionType.radio, options: _opts(['a'])),
        _q(id: 3, type: FilterQuestionType.checkbox, options: _opts(['a'])),
        _q(id: 4, type: FilterQuestionType.interests, options: _opts(['a'])),
        _q(id: 5, type: FilterQuestionType.text),
      ]);

      expect(loaded().questions.map((q) => q.id), [1, 2, 3, 4, 5]);
    });

    test('keeps any isRange question regardless of type', () async {
      await loadWith([
        _q(id: 1, type: FilterQuestionType.date, isRange: true),
        _q(id: 5, type: FilterQuestionType.height, isRange: true),
        _q(id: 6, type: FilterQuestionType.weight, isRange: true),
        _q(id: 9, type: FilterQuestionType.unknown, isRange: true),
      ]);

      expect(loaded().questions.map((q) => q.id), [1, 5, 6, 9]);
    });

    test('drops range-types sent with isRange=false', () async {
      // No single-value control exists for these, so rendering one would lie.
      await loadWith([
        _q(id: 1, type: FilterQuestionType.date),
        _q(id: 5, type: FilterQuestionType.height),
        _q(id: 6, type: FilterQuestionType.weight),
        _q(id: 11, type: FilterQuestionType.select, options: _opts(['a'])),
      ]);

      expect(loaded().questions.map((q) => q.id), [11]);
    });

    test('keeps unknown WITH options, drops unknown without', () async {
      await loadWith([
        _q(id: 7, type: FilterQuestionType.unknown, options: _opts(['a'])),
        _q(id: 8, type: FilterQuestionType.unknown),
        _q(id: 9, type: FilterQuestionType.unknown, options: const []),
      ]);

      expect(loaded().questions.map((q) => q.id), [7]);
    });

    test('seeded selections survive the load', () async {
      final seeded = MatchmakerExploreFilterCubit(
        getFilters: getFilters,
        initialSelections: const {11: SingleValueSelection('SA')},
      );
      addTearDown(seeded.close);
      when(() => getFilters()).thenAnswer(
        (_) async => Right([
          _q(id: 11, type: FilterQuestionType.select, options: _opts(['SA'])),
        ]),
      );

      await seeded.loadFilters();

      expect(seeded.buildQuestionFilters(), {
        11: ['SA'],
      });
    });
  });

  group('buildQuestionFilters — the facet half of the payload', () {
    test('select emits a single value', () async {
      await loadWith([
        _q(id: 11, type: FilterQuestionType.select, options: _opts(['SA'])),
      ]);
      cubit.setSingleValue(11, 'SA');

      expect(cubit.buildQuestionFilters(), {
        11: ['SA'],
      });
    });

    test('checkbox accumulates values in tap order', () async {
      await loadWith([
        _q(
          id: 22,
          type: FilterQuestionType.checkbox,
          options: _opts(['Honest', 'Ambitious', 'Family']),
        ),
      ]);
      cubit.toggleMultiValue(22, 'Honest');
      cubit.toggleMultiValue(22, 'Ambitious');
      cubit.toggleMultiValue(22, 'Family');

      expect(cubit.buildQuestionFilters(), {
        22: ['Honest', 'Ambitious', 'Family'],
      });
    });

    test('select/radio are MULTI-select — matching the user app', () async {
      // The wire carries comma-joined values, so single-select was a client
      // limitation, not a contract one.
      await loadWith([
        _q(
          id: 18,
          type: FilterQuestionType.radio,
          options: _opts(['Single', 'Separated']),
        ),
      ]);
      cubit.toggleMultiValue(18, 'Single');
      cubit.toggleMultiValue(18, 'Separated');

      expect(cubit.buildQuestionFilters(), {
        18: ['Single', 'Separated'],
      });
    });

    test('re-tapping the active single value clears it', () async {
      await loadWith([
        _q(id: 11, type: FilterQuestionType.select, options: _opts(['SA'])),
      ]);
      cubit.setSingleValue(11, 'SA');
      cubit.setSingleValue(11, 'SA');

      expect(cubit.buildQuestionFilters(), isEmpty);
    });

    test('toggling off the last multi value removes the key entirely', () async {
      await loadWith([
        _q(id: 22, type: FilterQuestionType.checkbox, options: _opts(['a'])),
      ]);
      cubit.toggleMultiValue(22, 'a');
      cubit.toggleMultiValue(22, 'a');

      expect(cubit.buildQuestionFilters(), isEmpty);
    });

    test('an empty string clears the selection (text cleared)', () async {
      await loadWith([_q(id: 30, type: FilterQuestionType.text)]);
      cubit.setSingleValue(30, 'نور');
      cubit.setSingleValue(30, '');

      expect(cubit.buildQuestionFilters(), isEmpty);
    });

    test('ranges are excluded from the facet half', () async {
      // They travel as RangeFrom/RangeTo, never as QuestionFilters.
      await loadWith([
        _q(id: 5, type: FilterQuestionType.height, isRange: true),
      ]);
      cubit.setRange(5, 160, 180);

      expect(cubit.buildQuestionFilters(), isEmpty);
    });
  });

  group('buildRangeFilters — trimming', () {
    test('both edges moved off the bounds → both sent', () async {
      await loadWith([
        _q(
          id: 5,
          type: FilterQuestionType.height,
          isRange: true,
          minValue: 140,
          maxValue: 210,
        ),
      ]);
      cubit.setRange(5, 160, 180);

      final r = cubit.buildRangeFilters();
      expect(r.from, {5: 160.0});
      expect(r.to, {5: 180.0});
    });

    test('a full-range selection sends NOTHING', () async {
      // This is the economy the user app is missing (step 4): sitting a slider
      // at its own bounds is not a filter.
      await loadWith([
        _q(
          id: 5,
          type: FilterQuestionType.height,
          isRange: true,
          minValue: 140,
          maxValue: 210,
        ),
      ]);
      cubit.setRange(5, 140, 210);

      final r = cubit.buildRangeFilters();
      expect(r.from, isEmpty);
      expect(r.to, isEmpty);
    });

    test('a one-sided range sends only the moved edge', () async {
      await loadWith([
        _q(
          id: 5,
          type: FilterQuestionType.height,
          isRange: true,
          minValue: 140,
          maxValue: 210,
        ),
      ]);
      cubit.setRange(5, 170, 210);

      final r = cubit.buildRangeFilters();
      expect(r.from, {5: 170.0});
      expect(r.to, isEmpty);
    });

    test('trims against the TYPE defaults when the server sent no bounds',
        () async {
      // date → 18..80, so a lower edge of 18 is the bound, not a constraint.
      await loadWith([
        _q(id: 1, type: FilterQuestionType.date, isRange: true),
      ]);
      cubit.setRange(1, 18, 50);

      final r = cubit.buildRangeFilters();
      expect(r.from, isEmpty);
      expect(r.to, {1: 50.0});
    });

    test('a range on an unknown question id is ignored', () async {
      await loadWith([
        _q(id: 5, type: FilterQuestionType.height, isRange: true),
      ]);
      cubit.setRange(999, 1, 2);

      final r = cubit.buildRangeFilters();
      expect(r.from, isEmpty);
      expect(r.to, isEmpty);
    });
  });

  group('clearAll', () {
    test('empties both halves of the payload', () async {
      await loadWith([
        _q(id: 11, type: FilterQuestionType.select, options: _opts(['SA'])),
        _q(id: 5, type: FilterQuestionType.height, isRange: true),
      ]);
      cubit.setSingleValue(11, 'SA');
      cubit.setRange(5, 160, 180);

      cubit.clearAll();

      expect(cubit.buildQuestionFilters(), isEmpty);
      expect(cubit.buildRangeFilters().from, isEmpty);
      expect(cubit.buildRangeFilters().to, isEmpty);
    });

    test('bumps resetVersion so open searchable facets collapse', () async {
      // Selections alone are not a sufficient signal: a facet the matchmaker
      // opened but never picked from has nothing in `selections` to change, so
      // without the counter it would sit open over an emptied sheet.
      await loadWith([
        _q(id: 11, type: FilterQuestionType.select, options: _opts(['SA'])),
      ]);
      final before = loaded().resetVersion;

      cubit.clearAll();

      expect(loaded().resetVersion, before + 1);
    });

    test('keeps the loaded questions — only selections are dropped', () async {
      await loadWith([
        _q(id: 11, type: FilterQuestionType.select, options: _opts(['SA'])),
      ]);

      cubit.clearAll();

      expect(loaded().questions, hasLength(1));
    });
  });

  group('exploreQuestionFiltersFromSelections — the pure converter', () {
    test('single and multi collapse to the same map shape', () {
      final out = exploreQuestionFiltersFromSelections(const {
        11: SingleValueSelection('SA'),
        22: MultiValueSelection(['a', 'b']),
      });

      expect(out, {
        11: ['SA'],
        22: ['a', 'b'],
      });
    });

    test('blank values and range selections are dropped', () {
      final out = exploreQuestionFiltersFromSelections(const {
        11: SingleValueSelection(''),
        22: MultiValueSelection(['', 'b']),
        5: RangeSelection(min: 1, max: 2),
      });

      expect(out, {
        22: ['b'],
      });
    });
  });

  group('mutations before load are no-ops', () {
    test('setters do nothing while unloaded', () {
      cubit.setSingleValue(11, 'SA');
      cubit.toggleMultiValue(22, 'a');
      cubit.setRange(5, 1, 2);
      cubit.clearAll();

      expect(cubit.state, isA<MatchmakerExploreFilterInitial>());
      expect(cubit.buildQuestionFilters(), isEmpty);
    });
  });

  group('buildRangeFilters — guards (step 4)', () {
    test('a range on a NON-range question is skipped', () async {
      // Same guard as the user app: effectiveMin/Max would be client-invented
      // type defaults, so there is nothing meaningful to trim against.
      await loadWith([
        _q(id: 11, type: FilterQuestionType.select, options: _opts(['a'])),
      ]);
      cubit.setRange(11, 2, 5);

      final r = cubit.buildRangeFilters();
      expect(r.from, isEmpty);
      expect(r.to, isEmpty);
    });

    test('an inverted range trips the debug assertion', () async {
      await loadWith([
        _q(
          id: 5,
          type: FilterQuestionType.height,
          isRange: true,
          minValue: 140,
          maxValue: 210,
        ),
      ]);
      cubit.setRange(5, 190, 150);

      expect(cubit.buildRangeFilters, throwsA(isA<AssertionError>()));
    });
  });

  group('isMultiSelect on load (E4)', () {
    Future<MatchmakerExploreFilterCubit> seeded(
      List<DiscoveryFilterQuestion> qs,
      Map<int, DiscoveryFilterSelection> selections,
    ) async {
      when(() => getFilters()).thenAnswer((_) async => Right(qs));
      final c = MatchmakerExploreFilterCubit(
        getFilters: getFilters,
        initialSelections: selections,
      );
      addTearDown(c.close);
      await c.loadFilters();
      return c;
    }

    test('a seeded 3-value selection collapses to 1 under isMultiSelect:false',
        () async {
      final c = await seeded(
        [
          _q(
            id: 11,
            type: FilterQuestionType.select,
            options: _opts(['a', 'b', 'c']),
            isMultiSelect: false,
          ),
        ],
        const {11: MultiValueSelection(['a', 'b', 'c'])},
      );

      expect(
        (c.state as MatchmakerExploreFilterLoaded).selections[11],
        const SingleValueSelection('a'),
      );
      expect(c.buildQuestionFilters(), {
        11: ['a'],
      });
    });

    test('the same seed survives intact when the flag is absent', () async {
      final c = await seeded(
        [_q(id: 11, type: FilterQuestionType.select, options: _opts(['a', 'b', 'c']))],
        const {11: MultiValueSelection(['a', 'b', 'c'])},
      );

      expect(c.buildQuestionFilters(), {
        11: ['a', 'b', 'c'],
      });
    });

    test('a multi already in state survives the flag flipping mid-session',
        () async {
      // Same scenario, same assertions as the user app's cubit test.
      await loadWith([
        _q(id: 11, type: FilterQuestionType.select, options: _opts(['a', 'b', 'c'])),
      ]);
      cubit.toggleMultiValue(11, 'a');
      cubit.toggleMultiValue(11, 'b');
      expect(cubit.buildQuestionFilters(), {
        11: ['a', 'b'],
      });

      cubit.setSingleValue(11, 'c');

      expect(cubit.buildQuestionFilters(), {
        11: ['c'],
      });
      expect(
        loaded().selections[11],
        const SingleValueSelection('c'),
      );
    });
  });

  group('loadFilters applies displayPriority order (E2)', () {
    test('the emitted questions are sorted, matching the user app', () async {
      await loadWith([
        _q(id: 3, type: FilterQuestionType.select, options: const [
          DiscoveryFilterOption(value: 'b', display: 'B', displayPriority: 2),
          DiscoveryFilterOption(value: 'a', display: 'A', displayPriority: 1),
        ]),
        _q(id: 9, type: FilterQuestionType.height), // dropped: isRange false
        _q(id: 1, type: FilterQuestionType.text, displayPriority: 1),
        _q(id: 2, type: FilterQuestionType.text, displayPriority: 2),
      ]);

      expect(loaded().questions.map((q) => q.id), [1, 2, 3]);
      expect(loaded().questions.last.options!.map((o) => o.value), ['a', 'b']);
    });
  });
}
