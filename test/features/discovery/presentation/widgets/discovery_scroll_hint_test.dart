import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_scroll_hint.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The fold hides itself by design — nothing peeks above it to suggest the
/// card scrolls. This is the only thing that says so, and it has to behave
/// like a coach mark: late, brief, and gone for good once understood.

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {
        'discovery': {'scroll_hint': 'مرّر للأسفل'},
      };
}

late ValueNotifier<double> offset;
late ValueNotifier<bool> dismissed;

Future<void> _pump(WidgetTester tester, {bool disableAnimations = false}) async {
  offset = ValueNotifier<double>(0);
  dismissed = ValueNotifier<bool>(false);
  addTearDown(offset.dispose);
  addTearDown(dismissed.dispose);

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
          home: Builder(
            builder: (inner) => MediaQuery(
              data: MediaQuery.of(
                inner,
              ).copyWith(disableAnimations: disableAnimations),
              child: Scaffold(
                body: DiscoveryScrollHint(
                  scrollOffset: offset,
                  dismissed: dismissed,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

double _opacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(find.byType(AnimatedOpacity))
    .opacity;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('stays out of the way while the card is still arriving', (
    tester,
  ) async {
    await _pump(tester);

    // Nothing at all for the first couple of seconds — a hint that fires
    // instantly competes with the card's own entrance.
    expect(_opacity(tester), 0);
    await tester.pump(const Duration(milliseconds: 1500));
    expect(_opacity(tester), 0);

    await tester.pump(DiscoveryScrollHint.delay);
    expect(_opacity(tester), 1);

    // Leave the repeating bob in a settled state for teardown.
    dismissed.value = true;
    await tester.pumpAndSettle();
  });

  testWidgets('a real scroll retires it immediately and for good', (
    tester,
  ) async {
    await _pump(tester);
    await tester.pump(DiscoveryScrollHint.delay);
    expect(_opacity(tester), 1);

    offset.value = DiscoveryScrollHint.learnedAt + 1;
    await tester.pump();

    expect(_opacity(tester), 0);
    // Latched above the deck, so the next profile does not teach it again.
    expect(dismissed.value, isTrue);
  });

  testWidgets('a stray wobble is not a scroll', (tester) async {
    await _pump(tester);

    offset.value = DiscoveryScrollHint.learnedAt - 1;
    await tester.pump(DiscoveryScrollHint.delay);

    expect(dismissed.value, isFalse);
    expect(_opacity(tester), 1);

    dismissed.value = true;
    await tester.pumpAndSettle();
  });

  testWidgets('never appears once it has already been learned', (tester) async {
    await _pump(tester);
    dismissed.value = true;
    await tester.pump();

    await tester.pump(DiscoveryScrollHint.delay);
    await tester.pump(DiscoveryScrollHint.delay);

    expect(_opacity(tester), 0);
  });

  testWidgets('it never eats a tap', (tester) async {
    await _pump(tester);
    await tester.pump(DiscoveryScrollHint.delay);

    // It floats over the card; swallowing gestures there would break the
    // swipe flow underneath it.
    expect(
      tester
          .widget<IgnorePointer>(
            find
                .descendant(
                  of: find.byType(DiscoveryScrollHint),
                  matching: find.byType(IgnorePointer),
                )
                .first,
          )
          .ignoring,
      isTrue,
    );

    dismissed.value = true;
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion keeps the message, drops the movement', (
    tester,
  ) async {
    await _pump(tester, disableAnimations: true);
    await tester.pump(DiscoveryScrollHint.delay);

    expect(_opacity(tester), 1);
    final shift = tester
        .widget<Transform>(
          find
              .ancestor(
                of: find.byIcon(Icons.keyboard_arrow_down_rounded),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .getTranslation();
    expect(shift.y, 0);

    dismissed.value = true;
    await tester.pumpAndSettle();
  });
}
