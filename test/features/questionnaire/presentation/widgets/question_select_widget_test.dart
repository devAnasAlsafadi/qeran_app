import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_search_field.dart';
import 'package:qeran/features/questionnaire/domain/entities/question_entity.dart';
import 'package:qeran/features/questionnaire/domain/entities/question_option_entity.dart';
import 'package:qeran/features/questionnaire/presentation/widgets/question_select_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

QuestionEntity _question(List<String> labels) => QuestionEntity(
  questionId: 'q1',
  text: 'Nationality',
  type: QuestionType.select,
  options: [
    for (var i = 0; i < labels.length; i++)
      QuestionOptionEntity(id: 'opt-$i', text: labels[i]),
  ],
);

/// `count` filler options so a test can sit exactly on the search threshold
/// without listing fifteen countries by hand.
List<String> _filler(int count, {String prefix = 'Country'}) =>
    [for (var i = 0; i < count; i++) '$prefix $i'];

Future<List<String>> _pump(
  WidgetTester tester, {
  required List<String> labels,
  String? selectedId,
  Locale locale = const Locale('en'),
}) async {
  final tapped = <String>[];
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      startLocale: locale,
      saveLocale: false,
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: QuestionSelectWidget(
                question: _question(labels),
                selectedOptionId: selectedId,
                onChanged: tapped.add,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tapped;
}

/// An option ROW carrying [label] — never the search field, which also holds
/// the typed text and would otherwise match every label the user types.
Finder _row(String label) => find.widgetWithText(InkWell, label);

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('the list itself', () {
    testWidgets('draws one row per option the backend sent', (tester) async {
      await _pump(tester, labels: ['Jordan', 'Armenia', 'Estonia']);

      expect(find.text('Jordan'), findsOneWidget);
      expect(find.text('Armenia'), findsOneWidget);
      expect(find.text('Estonia'), findsOneWidget);
    });

    testWidgets('a tap reports the option id, not its label', (tester) async {
      final tapped = await _pump(tester, labels: ['Jordan', 'Armenia']);

      await tester.tap(find.text('Armenia'));

      expect(tapped, ['opt-1']);
    });

    testWidgets('the chosen option is the only one drawn as chosen', (
      tester,
    ) async {
      await _pump(tester, labels: ['Jordan', 'Armenia'], selectedId: 'opt-1');

      // Weight is what separates them; asserted by style rather than by pixels
      // so the shipped font cannot change the answer.
      expect(
        tester.widget<Text>(find.text('Armenia')).style,
        QeranTypography.subtitle,
      );
      expect(
        tester.widget<Text>(find.text('Jordan')).style,
        QeranTypography.body,
      );
    });

    testWidgets('nothing selected draws every row unchosen', (tester) async {
      await _pump(tester, labels: ['Jordan', 'Armenia']);

      expect(
        tester.widget<Text>(find.text('Jordan')).style,
        QeranTypography.body,
      );
      expect(
        tester.widget<Text>(find.text('Armenia')).style,
        QeranTypography.body,
      );
    });
  });

  group('the search threshold', () {
    testWidgets('14 options carry no search box', (tester) async {
      await _pump(tester, labels: _filler(14));

      expect(find.byType(QeranSearchField), findsNothing);
    });

    testWidgets('15 options carry one, so the boundary is inclusive', (
      tester,
    ) async {
      await _pump(tester, labels: _filler(15));

      expect(find.byType(QeranSearchField), findsOneWidget);
    });

    testWidgets('a list well past the boundary still carries one', (
      tester,
    ) async {
      // Guards the threshold being an equality rather than a floor.
      await _pump(tester, labels: _filler(40));

      expect(find.byType(QeranSearchField), findsOneWidget);
    });
  });

  group('filtering', () {
    testWidgets('typing removes the rows that do not match', (tester) async {
      await _pump(tester, labels: [..._filler(14), 'Jordan', 'Armenia']);

      await _type(tester, 'Jordan');

      expect(_row('Jordan'), findsOneWidget);
      // The point of the whole feature: the others are GONE, not merely
      // outranked. A predicate that always passed would leave them here.
      expect(_row('Armenia'), findsNothing);
      expect(_row('Country 0'), findsNothing);
    });

    testWidgets('matches regardless of case (EN)', (tester) async {
      await _pump(tester, labels: [..._filler(14), 'Jordan']);

      await _type(tester, 'jOrDaN');

      expect(_row('Jordan'), findsOneWidget);
    });

    testWidgets('matches on a mid-word fragment', (tester) async {
      await _pump(tester, labels: [..._filler(14), 'Jordan']);

      await _type(tester, 'orda');

      expect(_row('Jordan'), findsOneWidget);
    });

    testWidgets('surrounding whitespace never hides a match', (tester) async {
      await _pump(tester, labels: [..._filler(14), 'Jordan']);

      await _type(tester, '  Jordan  ');

      expect(_row('Jordan'), findsOneWidget);
    });

    testWidgets('filters real Arabic labels under an Arabic locale', (
      tester,
    ) async {
      // Arabic script has no case, so `toLowerCase` is a no-op here — what
      // this proves is that the predicate matches Arabic substrings at all,
      // which is the half that actually ships to our default locale.
      await _pump(
        tester,
        labels: [..._filler(14, prefix: 'دولة'), 'الأردن', 'أرمينيا'],
        locale: const Locale('ar'),
      );

      await _type(tester, 'أرد');

      expect(_row('الأردن'), findsOneWidget);
      expect(_row('أرمينيا'), findsNothing);
      expect(_row('دولة 0'), findsNothing);
    });

    testWidgets('clearing the query restores the whole list', (tester) async {
      await _pump(tester, labels: [..._filler(14), 'Jordan', 'Armenia']);

      await _type(tester, 'Jordan');
      expect(_row('Armenia'), findsNothing);

      await _type(tester, '');

      expect(_row('Armenia'), findsOneWidget);
      expect(_row('Jordan'), findsOneWidget);
    });

    testWidgets('a filtered row still reports its selection', (tester) async {
      final tapped = await _pump(
        tester,
        labels: [..._filler(14), 'Jordan', 'Armenia'],
      );

      await _type(tester, 'Armenia');
      await tester.tap(_row('Armenia'));

      // Index 15 — the id must survive filtering, not become the row's new
      // position in the shortened list.
      expect(tapped, ['opt-15']);
    });
  });

  group('the empty result', () {
    testWidgets('a query matching nothing says so', (tester) async {
      await _pump(tester, labels: _filler(15));

      await _type(tester, 'zzzz');

      expect(find.text('No matching options'), findsOneWidget);
      expect(_row('Country 0'), findsNothing);
    });

    testWidgets('a question the backend sent empty says nothing', (
      tester,
    ) async {
      // No query means no empty SEARCH result. An options-less question is a
      // backend data gap and must not be dressed as one.
      await _pump(tester, labels: const []);

      expect(find.text('No matching options'), findsNothing);
    });
  });
}
