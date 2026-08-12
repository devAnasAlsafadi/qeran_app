import 'package:easy_localization/easy_localization.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_question.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_selection.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_option.dart';
import 'package:qeran/features/discovery/domain/entities/filter_question_type.dart';
import 'package:qeran/features/discovery/domain/usecases/get_discovery_filters_usecase.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_filter_cubit.dart';
import 'package:qeran/features/discovery/presentation/blocs/discovery_filter_state.dart';
import 'package:qeran/features/discovery/presentation/widgets/filter_question_renderer.dart';
import 'package:qeran/features/discovery/presentation/widgets/filter_searchable_facet.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

class _MockGetFilters extends Mock implements GetDiscoveryFiltersUseCase {}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('clear reset collapses an open searchable dropdown', (
    tester,
  ) async {
    final options = List<DiscoveryFilterOption>.generate(
      12,
      (index) => DiscoveryFilterOption(
        value: 'value-$index',
        display: 'Option $index',
      ),
    );
    final selected = <String>{'value-0'};
    var resetVersion = 0;
    late StateSetter rebuild;

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
              body: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return FilterSearchableFacet(
                    label: 'Nationality',
                    options: options,
                    isSelected: selected.contains,
                    onTap: (value) {},
                    resetVersion: resetVersion,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);

    rebuild(() {
      selected.clear();
      resetVersion++;
    });
    await tester.pump();

    expect(find.byIcon(Icons.search_rounded), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
  });

  testWidgets('radio question allows multiple selected values', (tester) async {
    final getFilters = _MockGetFilters();
    const question = DiscoveryFilterQuestion(
      id: 18,
      label: 'Marital status',
      type: FilterQuestionType.radio,
      isRange: false,
      options: [
        DiscoveryFilterOption(value: 'Single', display: 'Single'),
        DiscoveryFilterOption(value: 'Separated', display: 'Separated'),
      ],
    );
    when(() => getFilters()).thenAnswer((_) async => const Right([question]));
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

    await tester.tap(find.text('Single'));
    await tester.pump();
    await tester.tap(find.text('Separated'));
    await tester.pump();

    final selection =
        (cubit.state as DiscoveryFilterLoaded).selections[18]
            as MultiValueSelection;
    expect(selection.values, ['Single', 'Separated']);
    expect(cubit.buildPayload(), {'QuestionFilters[18]': 'Single,Separated'});
  });
}
