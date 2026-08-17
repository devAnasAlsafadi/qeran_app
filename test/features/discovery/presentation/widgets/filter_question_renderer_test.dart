import 'package:easy_localization/easy_localization.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/widgets/qeran_filter_chip_facet.dart';
import 'package:qeran/core/design_system/widgets/qeran_filter_searchable_facet.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_option.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_question.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_selection.dart';
import 'package:qeran/features/discovery/domain/entities/filter_question_type.dart';
import 'package:qeran/features/discovery/domain/usecases/get_discovery_filters_usecase.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_filter_cubit.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_filter_state.dart';
import 'package:qeran/features/discovery/presentation/widgets/filter_question_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The renderer's job after the facets moved to the design system: pick the
/// right facet for the option count, adapt the feature entity to
/// `QeranSelectableOption`, and wire taps to the cubit's multi-select path.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {
        'filters': {
          'search_hint': 'Search options',
          'search_empty': 'No matching options',
        },
      };
}

class _MockGetFilters extends Mock implements GetDiscoveryFiltersUseCase {}

DiscoveryFilterQuestion _q({
  required int id,
  required FilterQuestionType type,
  required int optionCount,
  bool? isMultiSelect,
  bool? isSearchable,
}) => DiscoveryFilterQuestion(
  id: id,
  label: 'Question $id',
  type: type,
  isRange: false,
  isMultiSelect: isMultiSelect,
  isSearchable: isSearchable,
  options: List<DiscoveryFilterOption>.generate(
    optionCount,
    (i) => DiscoveryFilterOption(value: 'v$i', display: 'Option $i'),
  ),
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Future<DiscoveryFilterCubit> pumpRenderer(
    WidgetTester tester,
    DiscoveryFilterQuestion question,
  ) async {
    final getFilters = _MockGetFilters();
    when(() => getFilters()).thenAnswer((_) async => Right([question]));
    final cubit = DiscoveryFilterCubit(getFilters: getFilters);
    await cubit.loadFilters();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/translations',
        assetLoader: const _StubAssetLoader(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(
              body: BlocProvider.value(
                value: cubit,
                child: BlocBuilder<DiscoveryFilterCubit, DiscoveryFilterState>(
                  builder: (context, state) {
                    final loaded = state as DiscoveryFilterLoaded;
                    return FilterQuestionRenderer(
                      question: question,
                      selection: loaded.selections[question.id],
                      resetVersion: loaded.resetVersion,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('a short option list renders as chips', (tester) async {
    await pumpRenderer(
      tester,
      _q(id: 11, type: FilterQuestionType.select, optionCount: 4),
    );

    expect(find.byType(QeranFilterChipFacet), findsOneWidget);
    expect(find.byType(QeranFilterSearchableFacet), findsNothing);
  });

  testWidgets('exactly at the threshold still renders as chips', (tester) async {
    // The cut-over is `> threshold`, not `>=` — pinned so a refactor cannot
    // silently shift it by one.
    await pumpRenderer(
      tester,
      _q(
        id: 11,
        type: FilterQuestionType.select,
        optionCount: kQeranSearchableFacetThreshold,
      ),
    );

    expect(find.byType(QeranFilterChipFacet), findsOneWidget);
  });

  testWidgets('one option past the threshold switches to the searchable facet',
      (tester) async {
    await pumpRenderer(
      tester,
      _q(
        id: 11,
        type: FilterQuestionType.select,
        optionCount: kQeranSearchableFacetThreshold + 1,
      ),
    );

    expect(find.byType(QeranFilterSearchableFacet), findsOneWidget);
    expect(find.byType(QeranFilterChipFacet), findsNothing);
  });

  testWidgets('radio question allows multiple selected values', (tester) async {
    final cubit = await pumpRenderer(
      tester,
      _q(id: 18, type: FilterQuestionType.radio, optionCount: 2),
    );

    await tester.tap(find.text('Option 0'));
    await tester.pump();
    await tester.tap(find.text('Option 1'));
    await tester.pump();

    final selection =
        (cubit.state as DiscoveryFilterLoaded).selections[18]
            as MultiValueSelection;
    expect(selection.values, ['v0', 'v1']);
    expect(cubit.buildPayload(), {'QuestionFilters[18]': 'v0,v1'});
  });

  testWidgets('a seeded single value toggles OFF on the first tap', (
    tester,
  ) async {
    // The pre-multi-select migration case. `toggleMultiValue` used to discard a
    // SingleValueSelection and start from an empty list, so the first tap
    // re-added the value: it rendered selected, was tapped, and stayed
    // selected. Both cubits seed the list from it now.
    final getFilters = _MockGetFilters();
    final question = _q(
      id: 18,
      type: FilterQuestionType.radio,
      optionCount: 2,
    );
    when(() => getFilters()).thenAnswer((_) async => Right([question]));
    final cubit = DiscoveryFilterCubit(
      getFilters: getFilters,
      initialSelections: const {18: SingleValueSelection('v0')},
    );
    await cubit.loadFilters();
    addTearDown(cubit.close);

    expect(cubit.buildPayload(), {'QuestionFilters[18]': 'v0'});

    cubit.toggleMultiValue(18, 'v0');

    expect(cubit.buildPayload(), isEmpty);
  });

  testWidgets('a seeded single value accepts a SECOND value', (tester) async {
    final getFilters = _MockGetFilters();
    final question = _q(
      id: 18,
      type: FilterQuestionType.radio,
      optionCount: 2,
    );
    when(() => getFilters()).thenAnswer((_) async => Right([question]));
    final cubit = DiscoveryFilterCubit(
      getFilters: getFilters,
      initialSelections: const {18: SingleValueSelection('v0')},
    );
    await cubit.loadFilters();
    addTearDown(cubit.close);

    cubit.toggleMultiValue(18, 'v1');

    expect(cubit.buildPayload(), {'QuestionFilters[18]': 'v0,v1'});
  });

  testWidgets('isSearchable:true forces the search box onto a TINY list', (
    tester,
  ) async {
    await pumpRenderer(
      tester,
      _q(id: 11, type: FilterQuestionType.select, optionCount: 3,
          isSearchable: true),
    );

    expect(find.byType(QeranFilterSearchableFacet), findsOneWidget);
    expect(find.byType(QeranFilterChipFacet), findsNothing);
  });

  testWidgets('isSearchable:false forces chips onto a LONG list', (
    tester,
  ) async {
    // Identical assertions to the matchmaker's renderer test — both read
    // `question.effectiveIsSearchable`, so the two apps cannot diverge.
    const count = kQeranSearchableFacetThreshold * 4;
    await pumpRenderer(
      tester,
      _q(id: 11, type: FilterQuestionType.select, optionCount: count,
          isSearchable: false),
    );

    expect(find.byType(QeranFilterChipFacet), findsOneWidget);
    expect(find.byType(QeranFilterSearchableFacet), findsNothing);
    expect(find.text('Option ${count - 1}'), findsOneWidget);
  });

  testWidgets('isMultiSelect:true forces multi on a RADIO question', (
    tester,
  ) async {
    final cubit = await pumpRenderer(
      tester,
      _q(
        id: 18,
        type: FilterQuestionType.radio,
        optionCount: 3,
        isMultiSelect: true,
      ),
    );

    await tester.tap(find.text('Option 0'));
    await tester.pump();
    await tester.tap(find.text('Option 2'));
    await tester.pump();

    expect(cubit.buildPayload(), {'QuestionFilters[18]': 'v0,v2'});
  });

  testWidgets('isMultiSelect:false forces single on a CHECKBOX question', (
    tester,
  ) async {
    // Identical assertions to the matchmaker's renderer test — both read
    // `question.effectiveIsMultiSelect`, so the two apps cannot diverge here.
    final cubit = await pumpRenderer(
      tester,
      _q(
        id: 21,
        type: FilterQuestionType.checkbox,
        optionCount: 3,
        isMultiSelect: false,
      ),
    );

    await tester.tap(find.text('Option 0'));
    await tester.pump();
    expect(cubit.buildPayload(), {'QuestionFilters[21]': 'v0'});

    await tester.tap(find.text('Option 2'));
    await tester.pump();
    expect(cubit.buildPayload(), {'QuestionFilters[21]': 'v2'});

    await tester.tap(find.text('Option 2'));
    await tester.pump();
    expect(cubit.buildPayload(), isEmpty);
  });

  testWidgets('checkbox question is multi-select too', (tester) async {
    final cubit = await pumpRenderer(
      tester,
      _q(id: 22, type: FilterQuestionType.checkbox, optionCount: 3),
    );

    await tester.tap(find.text('Option 0'));
    await tester.pump();
    await tester.tap(find.text('Option 2'));
    await tester.pump();

    expect(cubit.buildPayload(), {'QuestionFilters[22]': 'v0,v2'});
  });
}
