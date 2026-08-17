import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/widgets/qeran_filter_chip_facet.dart';
import 'package:qeran/core/design_system/widgets/qeran_filter_searchable_facet.dart';
import 'package:qeran/core/design_system/widgets/qeran_filter_text_facet.dart';
import 'package:qeran/core/design_system/widgets/qeran_range_slider.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_option.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_question.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_selection.dart';
import 'package:qeran/features/discovery/domain/entities/filter_question_type.dart';
import 'package:qeran/features/matchmaker/explore/domain/usecases/get_explore_filters_usecase.dart';
import 'package:qeran/features/matchmaker/explore/presentation/blocs/matchmaker_explore_filter_cubit.dart';
import 'package:qeran/features/matchmaker/explore/presentation/blocs/matchmaker_explore_filter_state.dart';
import 'package:qeran/features/matchmaker/explore/presentation/widgets/matchmaker_explore_filter_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The matchmaker renderer must pick the SAME facet the user app picks for the
/// same option count, and route select/radio through multi-select — the two
/// renderers are duplicated deliberately, so these mirror
/// `filter_question_renderer_test.dart`.
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

class _MockGetFilters extends Mock implements GetExploreFiltersUseCase {}

DiscoveryFilterQuestion _q({
  required int id,
  required FilterQuestionType type,
  int optionCount = 0,
  bool isRange = false,
  bool? isMultiSelect,
  bool? isSearchable,
}) => DiscoveryFilterQuestion(
  id: id,
  label: 'Question $id',
  type: type,
  isRange: isRange,
  isMultiSelect: isMultiSelect,
  isSearchable: isSearchable,
  options: isRange
      ? null
      : List<DiscoveryFilterOption>.generate(
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

  Future<MatchmakerExploreFilterCubit> pump(
    WidgetTester tester,
    DiscoveryFilterQuestion question,
  ) async {
    final getFilters = _MockGetFilters();
    when(() => getFilters()).thenAnswer((_) async => Right([question]));
    final cubit = MatchmakerExploreFilterCubit(getFilters: getFilters);
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
                child:
                    BlocBuilder<
                      MatchmakerExploreFilterCubit,
                      MatchmakerExploreFilterState
                    >(
                      builder: (context, state) {
                        final loaded =
                            state as MatchmakerExploreFilterLoaded;
                        return MatchmakerExploreFilterRenderer(
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
    await pump(
      tester,
      _q(id: 11, type: FilterQuestionType.select, optionCount: 4),
    );

    expect(find.byType(QeranFilterChipFacet), findsOneWidget);
    expect(find.byType(QeranFilterSearchableFacet), findsNothing);
  });

  testWidgets('exactly at the threshold still renders as chips', (tester) async {
    // Same `>` (not `>=`) cut-over as the user app — both read the shared
    // constant, so this pins that they agree.
    await pump(
      tester,
      _q(
        id: 11,
        type: FilterQuestionType.select,
        optionCount: kQeranSearchableFacetThreshold,
      ),
    );

    expect(find.byType(QeranFilterChipFacet), findsOneWidget);
  });

  testWidgets('one past the threshold switches to the searchable facet', (
    tester,
  ) async {
    await pump(
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
    final cubit = await pump(
      tester,
      _q(id: 18, type: FilterQuestionType.radio, optionCount: 2),
    );

    await tester.tap(find.text('Option 0'));
    await tester.pump();
    await tester.tap(find.text('Option 1'));
    await tester.pump();

    expect(cubit.buildQuestionFilters(), {
      18: ['v0', 'v1'],
    });
  });

  testWidgets('a seeded single value normalizes instead of vanishing', (
    tester,
  ) async {
    // The pre-multi-select migration case: a matchmaker who applied one value
    // before the change carries a SingleValueSelection. It must render as
    // selected, and the first tap must toggle it OFF rather than appending.
    final getFilters = _MockGetFilters();
    final question = _q(
      id: 18,
      type: FilterQuestionType.radio,
      optionCount: 2,
    );
    when(() => getFilters()).thenAnswer((_) async => Right([question]));
    final cubit = MatchmakerExploreFilterCubit(
      getFilters: getFilters,
      initialSelections: const {18: SingleValueSelection('v0')},
    );
    await cubit.loadFilters();
    addTearDown(cubit.close);

    expect(cubit.buildQuestionFilters(), {
      18: ['v0'],
    });

    cubit.toggleMultiValue(18, 'v0');

    expect(cubit.buildQuestionFilters(), isEmpty);
  });

  testWidgets('a seeded single value accepts a SECOND value', (tester) async {
    final getFilters = _MockGetFilters();
    final question = _q(
      id: 18,
      type: FilterQuestionType.radio,
      optionCount: 2,
    );
    when(() => getFilters()).thenAnswer((_) async => Right([question]));
    final cubit = MatchmakerExploreFilterCubit(
      getFilters: getFilters,
      initialSelections: const {18: SingleValueSelection('v0')},
    );
    await cubit.loadFilters();
    addTearDown(cubit.close);

    cubit.toggleMultiValue(18, 'v1');

    expect(cubit.buildQuestionFilters(), {
      18: ['v0', 'v1'],
    });
  });

  testWidgets('isMultiSelect:true forces multi on a RADIO question', (
    tester,
  ) async {
    // The dashboard flag beats the type. Radio would already infer multi here,
    // so the assertion that matters is that an EXPLICIT true is honoured and
    // routed through toggleMultiValue.
    final cubit = await pump(
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

    expect(cubit.buildQuestionFilters(), {
      18: ['v0', 'v2'],
    });
  });

  testWidgets('isMultiSelect:false forces single on a CHECKBOX question', (
    tester,
  ) async {
    // The inversion: checkbox infers multi, the dashboard says one. The second
    // tap must REPLACE the first, not add to it.
    final cubit = await pump(
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
    expect(cubit.buildQuestionFilters(), {
      21: ['v0'],
    });

    await tester.tap(find.text('Option 2'));
    await tester.pump();
    expect(cubit.buildQuestionFilters(), {
      21: ['v2'],
    });

    // And tapping the active one clears it — the single-select toggle.
    await tester.tap(find.text('Option 2'));
    await tester.pump();
    expect(cubit.buildQuestionFilters(), isEmpty);
  });

  testWidgets('isSearchable:true forces the search box onto a TINY list', (
    tester,
  ) async {
    await pump(
      tester,
      _q(
        id: 11,
        type: FilterQuestionType.select,
        optionCount: 3,
        isSearchable: true,
      ),
    );

    expect(find.byType(QeranFilterSearchableFacet), findsOneWidget);
    expect(find.byType(QeranFilterChipFacet), findsNothing);
  });

  testWidgets('isSearchable:false forces chips onto a LONG list', (
    tester,
  ) async {
    // Tariq's rule: the dashboard is the source of truth. Four times the
    // threshold still renders as chips, and every option is really there.
    const count = kQeranSearchableFacetThreshold * 4;
    await pump(
      tester,
      _q(
        id: 11,
        type: FilterQuestionType.select,
        optionCount: count,
        isSearchable: false,
      ),
    );

    expect(find.byType(QeranFilterChipFacet), findsOneWidget);
    expect(find.byType(QeranFilterSearchableFacet), findsNothing);
    expect(find.byIcon(Icons.search_rounded), findsNothing);
    expect(find.text('Option ${count - 1}'), findsOneWidget);
  });

  testWidgets('clearAll collapses an open searchable facet', (tester) async {
    final cubit = await pump(
      tester,
      _q(
        id: 11,
        type: FilterQuestionType.select,
        optionCount: kQeranSearchableFacetThreshold + 2,
      ),
    );

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);

    cubit.clearAll();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.search_rounded), findsNothing);
  });

  testWidgets('an isRange question renders the shared slider', (tester) async {
    await pump(
      tester,
      _q(id: 5, type: FilterQuestionType.height, isRange: true),
    );

    expect(find.byType(QeranRangeSlider), findsOneWidget);
    expect(find.byType(QeranFilterChipFacet), findsNothing);
  });

  testWidgets('a text question renders the shared text facet', (tester) async {
    await pump(tester, _q(id: 30, type: FilterQuestionType.text));

    expect(find.byType(QeranFilterTextFacet), findsOneWidget);
  });
}
