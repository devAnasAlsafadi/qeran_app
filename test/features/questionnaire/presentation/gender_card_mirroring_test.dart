// `hide TextDirection`: easy_localization re-exports intl, whose TextDirection
// shadows the dart:ui one these RTL/LTR tests drive.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/enum/gender.dart';
import 'package:qeran/features/questionnaire/presentation/screens/gender_selection/widgets/gender_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The card resolves its label through easy_localization, so the host has to
/// carry a live locale. Only the two keys it reads are stubbed.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async => const {
    'questionnaire': {'gender_male': 'Male', 'gender_female': 'Female'},
  };
}

/// The gender illustrations are drawn for Arabic — the man faces left, the
/// woman faces right — so with the man on the start edge they face each other
/// in RTL. LTR swaps which side each card sits on without mirroring the
/// artwork, which turned their backs to one another. These tests pin the flip
/// that fixes it, and pin that Arabic is left alone.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget host(Gender gender, TextDirection direction) {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          // Drives direction explicitly rather than via the locale: the flip
          // keys off ambient Directionality, which is what this pins.
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 200,
                  height: 260,
                  child: GenderCard(
                    gender: gender,
                    isSelected: false,
                    onTap: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Whether a horizontal flip is applied ABOVE the illustration.
  ///
  /// Scoped to Transforms that actually wrap the image, and matched on the
  /// matrix rather than on the widget's presence: MaterialApp puts Transforms
  /// of its own in the tree, and "a Transform exists" would pass on those.
  bool hasHorizontalFlip(WidgetTester tester) {
    final above = find.ancestor(
      of: find.byType(Image),
      matching: find.byType(Transform),
    );
    return tester
        .widgetList<Transform>(above)
        .any((t) => t.transform.storage[0] == -1.0);
  }

  for (final gender in Gender.values) {
    testWidgets('${gender.name}: LTR mirrors the illustration', (tester) async {
      await tester.pumpWidget(host(gender, TextDirection.ltr));
    await tester.pumpAndSettle();

      expect(
        hasHorizontalFlip(tester),
        isTrue,
        reason: 'LTR must flip the artwork so the pair faces inward',
      );
    });

    testWidgets('${gender.name}: RTL leaves the illustration alone', (
      tester,
    ) async {
      await tester.pumpWidget(host(gender, TextDirection.rtl));
    await tester.pumpAndSettle();

      expect(
        hasHorizontalFlip(tester),
        isFalse,
        reason: 'Arabic is the locale the artwork was drawn for — no flip',
      );
    });
  }

  // The wrapper reads the ambient Directionality rather than a captured value,
  // so a direction change on an already-mounted card takes effect. There is no
  // language control on this screen today, but the app reloads its tree on a
  // locale switch and this is the mechanism that carries the flip across.
  testWidgets('a direction change on a mounted card flips it', (tester) async {
    await tester.pumpWidget(host(Gender.male, TextDirection.rtl));
    await tester.pumpAndSettle();
    expect(hasHorizontalFlip(tester), isFalse);

    await tester.pumpWidget(host(Gender.male, TextDirection.ltr));
    await tester.pumpAndSettle();

    expect(hasHorizontalFlip(tester), isTrue);
  });

  // Cheap guard against the transform being hoisted somewhere it would drag
  // the whole animating card into its layer.
  testWidgets('the flip is isolated behind a RepaintBoundary', (tester) async {
    await tester.pumpWidget(host(Gender.female, TextDirection.ltr));
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.byType(Transform),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
  });
}
