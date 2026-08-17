import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_option.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_question.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_selection.dart';
import 'package:qeran/features/discovery/domain/entities/filter_question_type.dart';
import 'package:qeran/features/discovery/domain/usecases/get_discovery_filters_usecase.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_filter_cubit.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_filter_state.dart';

class _MockGetFilters extends Mock implements GetDiscoveryFiltersUseCase {}

DiscoveryFilterQuestion _q({
  required int id,
  required FilterQuestionType type,
  bool isRange = false,
  List<DiscoveryFilterOption>? options,
  int? minValue,
  int? maxValue,
  String? unit,
  bool? isMultiSelect,
  int? displayPriority,
}) => DiscoveryFilterQuestion(
  id: id,
  label: 'q$id',
  type: type,
  isRange: isRange,
  minValue: minValue,
  maxValue: maxValue,
  unit: unit,
  options: options,
  isMultiSelect: isMultiSelect,
  displayPriority: displayPriority,
);

void main() {
  late _MockGetFilters getFilters;
  late DiscoveryFilterCubit cubit;

  setUp(() {
    getFilters = _MockGetFilters();
    cubit = DiscoveryFilterCubit(getFilters: getFilters);
  });

  tearDown(() => cubit.close());

  Future<void> loadWith(List<DiscoveryFilterQuestion> qs) async {
    when(() => getFilters()).thenAnswer((_) async => Right(qs));
    await cubit.loadFilters();
  }

  group('buildPayload — range selections', () {
    test('height range emits RangeFrom[id] + RangeTo[id]', () async {
      await loadWith([
        _q(id: 5, type: FilterQuestionType.height, isRange: true),
      ]);
      cubit.setRange(5, 160, 180);

      expect(cubit.buildPayload(), const {
        'RangeFrom[5]': '160',
        'RangeTo[5]': '180',
      });
    });

    test(
      'date (age range) emits ONLY the edge the user moved',
      () async {
        // REWRITTEN in step 4. This previously asserted
        // `{RangeFrom[1]: 18, RangeTo[1]: 50}` — pinning the bug Tariq
        // described: `date` with no backend bounds defaults to 18..80, so
        // RangeFrom[1]=18 echoed the question's own floor back at the server.
        // The server treats a present edge as a constraint and excludes rows
        // with no value on that field, so the "harmless" edge silently dropped
        // profiles. Only the moved upper thumb is a real constraint.
        await loadWith([
          _q(id: 1, type: FilterQuestionType.date, isRange: true),
        ]);
        cubit.setRange(1, 18, 50);

        expect(cubit.buildPayload(), const {'RangeTo[1]': '50'});
      },
    );

    test('a full-range selection contributes no keys at all', () async {
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

      expect(cubit.buildPayload(), isEmpty);
    });

    test('a range on a NON-range question is skipped entirely', () async {
      // effectiveMin/effectiveMax would be client-invented type defaults here,
      // so there is nothing meaningful to trim against.
      await loadWith([
        _q(
          id: 11,
          type: FilterQuestionType.select,
          options: const [DiscoveryFilterOption(value: 'SA', display: 's')],
        ),
      ]);
      cubit.setRange(11, 2, 5);

      expect(cubit.buildPayload(), isEmpty);
    });

    test('an inverted range trips the debug assertion', () async {
      // Structurally impossible through the slider. The assert makes it a test
      // failure rather than a silent wrong request; release builds fall through
      // to warn-and-skip, which asserts-enabled test runs cannot reach.
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

      expect(cubit.buildPayload, throwsA(isA<AssertionError>()));
    });
  });

  group('buildPayload — single-value selections', () {
    test('select emits QuestionFilters[id]=value', () async {
      await loadWith([
        _q(
          id: 11,
          type: FilterQuestionType.select,
          options: const [DiscoveryFilterOption(value: 'SA', display: 'سعودي')],
        ),
      ]);
      cubit.setSingleValue(11, 'SA');

      expect(cubit.buildPayload(), const {'QuestionFilters[11]': 'SA'});
    });

    test('radio emits QuestionFilters[id]=value', () async {
      await loadWith([
        _q(
          id: 18,
          type: FilterQuestionType.radio,
          options: const [
            DiscoveryFilterOption(value: 'Single', display: 'عازب'),
          ],
        ),
      ]);
      cubit.setSingleValue(18, 'Single');

      expect(cubit.buildPayload(), const {'QuestionFilters[18]': 'Single'});
    });

    test('text emits QuestionFilters[id]=trimmed value', () async {
      await loadWith([_q(id: 30, type: FilterQuestionType.text)]);
      cubit.setSingleValue(30, 'Ahmad');

      expect(cubit.buildPayload(), const {'QuestionFilters[30]': 'Ahmad'});
    });

    test('empty string removes the selection (text cleared)', () async {
      await loadWith([_q(id: 30, type: FilterQuestionType.text)]);
      cubit.setSingleValue(30, 'Ahmad');
      cubit.setSingleValue(30, '');

      expect(cubit.buildPayload(), isEmpty);
    });

    test('toggling the active option clears it', () async {
      await loadWith([
        _q(
          id: 18,
          type: FilterQuestionType.radio,
          options: const [
            DiscoveryFilterOption(value: 'Single', display: 'عازب'),
          ],
        ),
      ]);
      cubit.setSingleValue(18, 'Single');
      cubit.setSingleValue(18, 'Single');

      expect(cubit.buildPayload(), isEmpty);
    });
  });

  group('buildPayload — multi-value selections (comma-joined)', () {
    test('checkbox emits QuestionFilters[id]=v1,v2,v3', () async {
      await loadWith([
        _q(
          id: 21,
          type: FilterQuestionType.checkbox,
          options: const [
            DiscoveryFilterOption(value: 'AR', display: 'العربية'),
            DiscoveryFilterOption(value: 'EN', display: 'الإنجليزية'),
            DiscoveryFilterOption(value: 'FR', display: 'الفرنسية'),
          ],
        ),
      ]);
      cubit.toggleMultiValue(21, 'AR');
      cubit.toggleMultiValue(21, 'EN');
      cubit.toggleMultiValue(21, 'FR');

      expect(cubit.buildPayload(), const {'QuestionFilters[21]': 'AR,EN,FR'});
    });

    test('interests emits QuestionFilters[id]=comma-joined', () async {
      await loadWith([
        _q(
          id: 22,
          type: FilterQuestionType.interests,
          options: const [
            DiscoveryFilterOption(value: 'Honest', display: 'صادق'),
            DiscoveryFilterOption(value: 'Ambitious', display: 'طموح'),
          ],
        ),
      ]);
      cubit.toggleMultiValue(22, 'Honest');
      cubit.toggleMultiValue(22, 'Ambitious');

      expect(cubit.buildPayload(), const {
        'QuestionFilters[22]': 'Honest,Ambitious',
      });
    });

    test(
      'radio/select values can be comma-joined by the multi-select UI',
      () async {
        await loadWith([
          _q(
            id: 18,
            type: FilterQuestionType.radio,
            options: const [
              DiscoveryFilterOption(value: 'Single', display: 'عازب'),
              DiscoveryFilterOption(value: 'Separated', display: 'منفصل'),
            ],
          ),
        ]);
        cubit.toggleMultiValue(18, 'Single');
        cubit.toggleMultiValue(18, 'Separated');

        expect(cubit.buildPayload(), const {
          'QuestionFilters[18]': 'Single,Separated',
        });
      },
    );

    test('toggling off the last value removes the key entirely', () async {
      await loadWith([
        _q(
          id: 21,
          type: FilterQuestionType.checkbox,
          options: const [
            DiscoveryFilterOption(value: 'AR', display: 'العربية'),
          ],
        ),
      ]);
      cubit.toggleMultiValue(21, 'AR');
      cubit.toggleMultiValue(21, 'AR');

      expect(cubit.buildPayload(), isEmpty);
    });
  });

  group('buildPayload — combined / clear', () {
    test('full mixed payload matches the backend example', () async {
      await loadWith([
        _q(id: 1, type: FilterQuestionType.date, isRange: true),
        _q(id: 5, type: FilterQuestionType.height, isRange: true),
        _q(
          id: 18,
          type: FilterQuestionType.radio,
          options: const [DiscoveryFilterOption(value: 'Single', display: 's')],
        ),
        _q(
          id: 11,
          type: FilterQuestionType.select,
          options: const [DiscoveryFilterOption(value: 'SA', display: 's')],
        ),
        _q(
          id: 22,
          type: FilterQuestionType.interests,
          options: const [
            DiscoveryFilterOption(value: 'Honest', display: 'h'),
            DiscoveryFilterOption(value: 'Ambitious', display: 'a'),
            DiscoveryFilterOption(value: 'FamilyOriented', display: 'f'),
          ],
        ),
      ]);
      cubit.setRange(1, 18, 50);
      cubit.setRange(5, 160, 180);
      cubit.setSingleValue(18, 'Single');
      cubit.setSingleValue(11, 'SA');
      cubit.toggleMultiValue(22, 'Honest');
      cubit.toggleMultiValue(22, 'Ambitious');
      cubit.toggleMultiValue(22, 'FamilyOriented');

      // REWRITTEN in step 4: `RangeFrom[1]` is gone. Age 18..50 leaves the
      // lower thumb on the question's own floor (date defaults to 18..80), so
      // that edge trims away; height 160..180 sits inside 50..200, so both of
      // its edges survive. Kept as a MIXED payload deliberately — it now pins
      // that trimming applies per-edge inside a combined request rather than
      // all-or-nothing.
      expect(cubit.buildPayload(), const {
        'RangeTo[1]': '50',
        'RangeFrom[5]': '160',
        'RangeTo[5]': '180',
        'QuestionFilters[18]': 'Single',
        'QuestionFilters[11]': 'SA',
        'QuestionFilters[22]': 'Honest,Ambitious,FamilyOriented',
      });
    });

    test('clearAll empties the payload', () async {
      await loadWith([
        _q(id: 5, type: FilterQuestionType.height, isRange: true),
      ]);
      cubit.setRange(5, 160, 180);
      cubit.clearAll();

      expect(cubit.buildPayload(), isEmpty);
      expect((cubit.state as DiscoveryFilterLoaded).resetVersion, 1);
    });
  });

  group('_filterOutUnusable', () {
    test('drops unknown-type questions without options', () async {
      await loadWith([
        _q(
          id: 1,
          type: FilterQuestionType.select,
          options: const [DiscoveryFilterOption(value: 'a', display: 'A')],
        ),
        _q(id: 2, type: FilterQuestionType.unknown, options: null),
      ]);
      final loaded = cubit.state as DiscoveryFilterLoaded;
      expect(loaded.questions.map((q) => q.id), [1]);
    });

    test('drops range-types when isRange=false (defensive)', () async {
      await loadWith([
        _q(id: 5, type: FilterQuestionType.height /* isRange: false */),
        _q(id: 6, type: FilterQuestionType.weight, isRange: true),
      ]);
      final loaded = cubit.state as DiscoveryFilterLoaded;
      expect(loaded.questions.map((q) => q.id), [6]);
    });

    test('keeps text and unknown-with-options', () async {
      await loadWith([
        _q(id: 30, type: FilterQuestionType.text),
        _q(
          id: 99,
          type: FilterQuestionType.unknown,
          options: const [DiscoveryFilterOption(value: 'a', display: 'A')],
        ),
      ]);
      final loaded = cubit.state as DiscoveryFilterLoaded;
      expect(loaded.questions.map((q) => q.id), [30, 99]);
    });
  });

  group('loadFilters error path', () {
    test('emits Failure on Left', () async {
      when(
        () => getFilters(),
      ).thenAnswer((_) async => const Left(ServerFailure(message: 'oops')));

      await cubit.loadFilters();

      expect(cubit.state, isA<DiscoveryFilterFailure>());
      expect((cubit.state as DiscoveryFilterFailure).message, 'oops');
    });
  });

  group('isMultiSelect on load (E4)', () {
    Future<DiscoveryFilterCubit> seeded(
      List<DiscoveryFilterQuestion> qs,
      Map<int, DiscoveryFilterSelection> selections,
    ) async {
      when(() => getFilters()).thenAnswer((_) async => Right(qs));
      final c = DiscoveryFilterCubit(
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
            options: const [
              DiscoveryFilterOption(value: 'a', display: 'A'),
              DiscoveryFilterOption(value: 'b', display: 'B'),
              DiscoveryFilterOption(value: 'c', display: 'C'),
            ],
            isMultiSelect: false,
          ),
        ],
        const {11: MultiValueSelection(['a', 'b', 'c'])},
      );

      expect(
        (c.state as DiscoveryFilterLoaded).selections[11],
        const SingleValueSelection('a'),
      );
      expect(c.buildPayload(), {'QuestionFilters[11]': 'a'});
    });

    test('the same seed survives intact when the flag is absent', () async {
      final c = await seeded(
        [_q(id: 11, type: FilterQuestionType.select)],
        const {11: MultiValueSelection(['a', 'b', 'c'])},
      );

      expect(c.buildPayload(), {'QuestionFilters[11]': 'a,b,c'});
    });

    test('a multi already in state survives the flag flipping mid-session',
        () async {
      // The sheet is open with the OLD flag; the state holds a MultiValue while
      // the renderer now shows a single-select facet. setSingleValue must
      // replace it cleanly instead of throwing or merging.
      await loadWith([_q(id: 11, type: FilterQuestionType.select)]);
      cubit.toggleMultiValue(11, 'a');
      cubit.toggleMultiValue(11, 'b');
      expect(cubit.buildPayload(), {'QuestionFilters[11]': 'a,b'});

      cubit.setSingleValue(11, 'c');

      expect(cubit.buildPayload(), {'QuestionFilters[11]': 'c'});
      expect(
        (cubit.state as DiscoveryFilterLoaded).selections[11],
        const SingleValueSelection('c'),
      );
    });
  });

  group('loadFilters applies displayPriority order (E2)', () {
    test('the emitted questions are sorted, and only sorted once', () async {
      // Sorting belongs at load, not in build: the renderer must be able to
      // trust state order. `_filterOutUnusable` runs first, so a dropped
      // question cannot reappear through the sort.
      await loadWith([
        _q(id: 3, type: FilterQuestionType.select, options: const [
          DiscoveryFilterOption(value: 'b', display: 'B', displayPriority: 2),
          DiscoveryFilterOption(value: 'a', display: 'A', displayPriority: 1),
        ]),
        _q(id: 9, type: FilterQuestionType.date), // dropped: isRange false
        _q(id: 1, type: FilterQuestionType.text, displayPriority: 1),
        _q(id: 2, type: FilterQuestionType.text, displayPriority: 2),
      ]);

      final loaded = cubit.state as DiscoveryFilterLoaded;
      expect(loaded.questions.map((q) => q.id), [1, 2, 3]);
      expect(
        loaded.questions.last.options!.map((o) => o.value),
        ['a', 'b'],
        reason: 'options sorted too',
      );
    });
  });
}
