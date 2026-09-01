import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/questionnaire/presentation/widgets/question_text_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The long bio answer — the one field in the product a member writes
/// paragraphs into. Its resting height and its ceiling are pinned here
/// because both are judgement calls, not defaults.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async => {
    'questionnaire': {'answer_hint': 'hint-${locale.languageCode}'},
  };
}

Future<List<String>> _pump(
  WidgetTester tester, {
  String? currentAnswer,
  String? hintText,
  int? maxLength,
  Locale locale = const Locale('en'),
  ui.TextDirection direction = ui.TextDirection.ltr,
}) async {
  final typed = <String>[];
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      startLocale: locale,
      // Without this the first pump persists its locale and a later pump in
      // the same test silently reuses it instead of the one asked for.
      saveLocale: false,
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Scaffold(
            body: Directionality(
              textDirection: direction,
              child: QuestionTextWidget(
                currentAnswer: currentAnswer,
                hintText: hintText,
                maxLength: maxLength,
                onChanged: typed.add,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return typed;
}

TextField _field(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('the room it gives', () {
    testWidgets('opens at two lines, so an untouched form stays light', (
      tester,
    ) async {
      await _pump(tester);

      expect(_field(tester).minLines, 2);
    });

    testWidgets('grows to twelve before it starts scrolling', (tester) async {
      // Twelve is generous on purpose: the Next button lives outside the
      // scroll view, so a tall field cannot push it out of reach.
      await _pump(tester);

      expect(_field(tester).maxLines, 12);
    });

    testWidgets('the ceiling is well clear of the floor', (tester) async {
      // Guards the pair as a RANGE. Collapsing them to one value would give a
      // fixed box that never grows — the behaviour we are moving away from.
      await _pump(tester);

      final field = _field(tester);
      expect(field.maxLines! - field.minLines!, greaterThan(5));
    });
  });

  group('typing into it', () {
    testWidgets('keeps the return key, so paragraphs are possible', (
      tester,
    ) async {
      await _pump(tester);

      final field = _field(tester);
      expect(field.keyboardType, TextInputType.multiline);
      expect(field.textInputAction, TextInputAction.newline);
    });

    testWidgets('reports what was typed', (tester) async {
      final typed = await _pump(tester);

      await tester.enterText(find.byType(TextField), 'a line');

      expect(typed, ['a line']);
    });

    testWidgets('opens on the answer already saved', (tester) async {
      await _pump(tester, currentAnswer: 'written earlier');

      expect(find.text('written earlier'), findsOneWidget);
    });
  });

  group('the placeholder', () {
    testWidgets('falls back to the questionnaire hint', (tester) async {
      await _pump(tester);

      expect(find.text('hint-en'), findsOneWidget);
    });

    testWidgets('follows the locale', (tester) async {
      // Arabic is the default locale, so this path ships to most members.
      await _pump(tester, locale: const Locale('ar'));

      expect(find.text('hint-ar'), findsOneWidget);
    });

    testWidgets('yields to the profile-edit override', (tester) async {
      await _pump(tester, hintText: 'own hint');

      expect(find.text('own hint'), findsOneWidget);
      expect(find.text('hint-en'), findsNothing);
    });
  });

  group('under either direction', () {
    testWidgets('rests and grows the same in RTL as in LTR', (tester) async {
      // The directional painting itself lives in QeranTextField and is pinned
      // there; what matters here is that mirroring costs the field no height.
      await _pump(tester, direction: ui.TextDirection.ltr);
      final ltr = _field(tester);

      await _pump(
        tester,
        locale: const Locale('ar'),
        direction: ui.TextDirection.rtl,
      );
      final rtl = _field(tester);

      expect(rtl.minLines, ltr.minLines);
      expect(rtl.maxLines, ltr.maxLines);
      expect(tester.takeException(), isNull);
    });
  });
}
