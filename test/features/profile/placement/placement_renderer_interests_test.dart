import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_chip.dart';
import 'package:qeran/features/profile/data/models/placement_model.dart';
import 'package:qeran/features/profile/domain/entities/placement.dart';
import 'package:qeran/features/profile/domain/entities/placement_code.dart';
import 'package:qeran/features/profile/domain/entities/placement_item.dart';
import 'package:qeran/features/profile/domain/entities/placement_item_type.dart';
import 'package:qeran/features/profile/domain/entities/placement_value.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/interests_section.dart';
import 'package:qeran/features/profile/presentation/widgets/placement/placement_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// #8 — القيم / الاهتمامات.
///
/// The backend ships them as the placements group with `placementCode: 5`
/// (Q22 "الصفات الشخصية" + Q23 "الاهتمامات"), each item's `display` being the
/// selected list. These tests pin the whole chain: the wire shape parses, and
/// the renderer emits the section in both layouts.
///
/// They also guard the `_bucket()` duplicate handling — the singleton codes
/// used to discard a second placement outright.

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

/// The exact payload shape from the backend doc.
Map<String, dynamic> get _interestsJson => {
  'placement': 'interests',
  'placementCode': 5,
  'placementName': 'الاهتمامات',
  'items': [
    {
      'questionId': 22,
      'question': 'الصفات الشخصية',
      'type': 'interests',
      'display': ['صبور', 'طموح'],
    },
    {
      'questionId': 23,
      'question': 'الاهتمامات',
      'type': 'interests',
      'display': ['القراءة', 'السفر'],
    },
  ],
};

Placement _narrative(PlacementCode code, String body) => Placement(
  code: code,
  name: 'نبذة',
  items: [
    PlacementItem(
      questionId: 1,
      question: 'q',
      type: PlacementItemType.text,
      value: PlacementSingle(body),
      display: PlacementSingle(body),
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  List<Placement> placements, {
  bool asCards = false,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: PlacementRenderer(
                placements: placements,
                asCards: asCards,
                includeNarrative: !asCards,
              ),
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

  group('the wire shape parses', () {
    test('placementCode 5 → PlacementCode.interests', () {
      final p = PlacementModel.fromJson(_interestsJson).toEntity();
      expect(p.code, PlacementCode.interests);
      expect(p.name, 'الاهتمامات');
      expect(p.items, hasLength(2));
    });

    test('type "interests" is a known item type, not unknown', () {
      final p = PlacementModel.fromJson(_interestsJson).toEntity();
      expect(
        p.items.map((i) => i.type),
        everyElement(PlacementItemType.interests),
      );
    });

    test('a list `display` becomes PlacementMulti, not an empty single', () {
      final p = PlacementModel.fromJson(_interestsJson).toEntity();
      expect(p.items.first.display, isA<PlacementMulti>());
      expect(
        (p.items.first.display as PlacementMulti).values,
        ['صبور', 'طموح'],
      );
    });
  });

  group('the renderer emits it', () {
    testWidgets('flat layout renders every selected value as a chip', (
      tester,
    ) async {
      final p = PlacementModel.fromJson(_interestsJson).toEntity();
      await _pump(tester, [p]);

      expect(find.byType(InterestsSection), findsOneWidget);
      expect(find.byType(QeranChip), findsNWidgets(4));
      for (final label in ['صبور', 'طموح', 'القراءة', 'السفر']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('card layout renders it too', (tester) async {
      // The full-profile / matchmaker-profile bodies use asCards +
      // includeNarrative: false, so interests must survive that path as well.
      final p = PlacementModel.fromJson(_interestsJson).toEntity();
      await _pump(tester, [p], asCards: true);

      expect(find.byType(InterestsSection), findsOneWidget);
      expect(find.text('القراءة'), findsOneWidget);
    });

    testWidgets('two interests groups both render — neither is dropped', (
      tester,
    ) async {
      final p = PlacementModel.fromJson(_interestsJson).toEntity();
      await _pump(tester, [p, p]);

      expect(find.byType(InterestsSection), findsNWidgets(2));
    });
  });

  group('_bucket() list-vs-singleton behaviour, pinned', () {
    testWidgets('several defaultGroup sections all render', (tester) async {
      // Code 0 is a list bucket — the Q&A groups (الدين ونمط الحياة, الحياة
      // الزوجية…) arrive as several placements and every one must render.
      await _pump(tester, [
        Placement(
          code: PlacementCode.defaultGroup,
          name: 'الدين ونمط الحياة',
          items: _narrative(PlacementCode.defaultGroup, 'أ').items,
        ),
        Placement(
          code: PlacementCode.defaultGroup,
          name: 'الحياة الزوجية',
          items: _narrative(PlacementCode.defaultGroup, 'ب').items,
        ),
      ]);

      expect(find.text('الدين ونمط الحياة'), findsOneWidget);
      expect(find.text('الحياة الزوجية'), findsOneWidget);
    });

    testWidgets('a duplicate aboutMe is first-wins, not doubled', (
      tester,
    ) async {
      // Documents the singleton `??=`: the profile has ONE نبذة, so a repeat
      // is ignored rather than producing a second header. The backend sends
      // one group per code, so this path is unexercised in practice.
      await _pump(tester, [
        _narrative(PlacementCode.aboutMe, 'الجزء الأول'),
        _narrative(PlacementCode.aboutMe, 'الجزء الثاني'),
      ]);

      expect(find.text('الجزء الأول'), findsOneWidget);
      expect(find.text('نبذة'), findsOneWidget);
    });
  });
}
