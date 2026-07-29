import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/profile/data/models/placement_value_model.dart';
import 'package:qeran/features/profile/domain/entities/placement.dart';
import 'package:qeran/features/profile/domain/entities/placement_code.dart';
import 'package:qeran/features/profile/domain/entities/placement_item.dart';
import 'package:qeran/features/profile/domain/entities/placement_item_type.dart';
import 'package:qeran/features/profile/domain/entities/placement_value.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/interests_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The backend puts SEVERAL questions inside the one `interests` placement:
/// personal traits (questionId 22) and hobbies (23) arrive as two items of a
/// single group named "الاهتمامات".
///
/// The section used to flatten every item into one wrap under the group's name,
/// so both answers merged into a single unlabelled pile and the traits question
/// looked like it had gone missing — it was on screen, just nameless and mixed
/// in with the hobbies.

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

PlacementItem _item({
  required int questionId,
  required String question,
  required Object? display,
}) => PlacementItem(
  questionId: questionId,
  question: question,
  type: PlacementItemType.interests,
  value: parsePlacementValue(display),
  display: parsePlacementValue(display),
);

/// Exactly the payload documented by the backend.
Placement _interests({Object? traits, Object? hobbies}) => Placement(
  code: PlacementCode.interests,
  name: 'الاهتمامات',
  items: [
    if (traits != null)
      _item(questionId: 22, question: 'الصفات الشخصية', display: traits),
    if (hobbies != null)
      _item(questionId: 23, question: 'الاهتمامات', display: hobbies),
  ],
);

Future<void> _pump(WidgetTester tester, Placement placement) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      startLocale: const Locale('ar'),
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: InterestsSection(placement: placement),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('both questions get their own heading', (tester) async {
    await _pump(
      tester,
      _interests(
        traits: const ['❤️ رومانسي', '🤝 وفي', '🕌 متدين', '🎁 كريم'],
        hobbies: const ['⚽️ الرياضة', '🍳 الطبخ'],
      ),
    );

    // Was: one "الاهتمامات" heading over all six chips.
    expect(find.text('الصفات الشخصية'), findsOneWidget);
    expect(find.text('الاهتمامات'), findsOneWidget);
  });

  testWidgets('every answer is rendered, under the right heading', (
    tester,
  ) async {
    await _pump(
      tester,
      _interests(
        traits: const ['❤️ رومانسي', '🤝 وفي'],
        hobbies: const ['⚽️ الرياضة', '🍳 الطبخ'],
      ),
    );

    for (final chip in ['❤️ رومانسي', '🤝 وفي', '⚽️ الرياضة', '🍳 الطبخ']) {
      expect(find.text(chip), findsOneWidget);
    }

    // Traits come first, so their chips sit above the hobbies heading.
    final traitChip = tester.getRect(find.text('🤝 وفي')).bottom;
    final hobbiesHeading = tester.getRect(find.text('الاهتمامات')).top;
    expect(traitChip, lessThanOrEqualTo(hobbiesHeading));
  });

  testWidgets('a single-choice answer arrives as a String, not a List', (
    tester,
  ) async {
    // 16 users in production have exactly one trait and 9 one hobby. The wire
    // type collapses to a bare String for them — a parser expecting an array
    // would drop the answer entirely.
    await _pump(
      tester,
      _interests(traits: '❤️ رومانسي', hobbies: '⚽️ الرياضة'),
    );

    expect(find.text('❤️ رومانسي'), findsOneWidget);
    expect(find.text('⚽️ الرياضة'), findsOneWidget);
    expect(find.text('الصفات الشخصية'), findsOneWidget);
  });

  testWidgets('an unanswered question contributes no empty heading', (
    tester,
  ) async {
    await _pump(tester, _interests(hobbies: const ['⚽️ الرياضة']));

    expect(find.text('الصفات الشخصية'), findsNothing);
    expect(find.text('الاهتمامات'), findsOneWidget);
  });

  testWidgets('nothing answered renders nothing at all', (tester) async {
    await _pump(tester, _interests(traits: const <String>[]));

    expect(find.byType(Wrap), findsNothing);
  });

  testWidgets('falls back to the group name when a question has no text', (
    tester,
  ) async {
    await _pump(
      tester,
      Placement(
        code: PlacementCode.interests,
        name: 'الاهتمامات',
        items: [
          _item(questionId: 23, question: '  ', display: const ['⚽️ الرياضة']),
        ],
      ),
    );

    expect(find.text('الاهتمامات'), findsOneWidget);
  });

  test('the parser tolerates both wire shapes', () {
    expect(parsePlacementValue('Romantic'), const PlacementSingle('Romantic'));
    expect(
      parsePlacementValue(const ['Romantic', 'Loyal']),
      const PlacementMulti(['Romantic', 'Loyal']),
    );
    expect(parsePlacementValue(null), const PlacementSingle(''));
  });
}
