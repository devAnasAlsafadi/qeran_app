import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/theme/app_color.dart';
import 'package:qeran/core/utils/app_dimens.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_action_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Layout regression suite for the lower sheet — verifies the action
/// bar is PINNED at the bottom regardless of how tall the info-panel
/// content is, and that the scroll view absorbs overflow.
///
/// `_LowerSheet` is private to `discovery_view.dart`, so this file
/// reconstructs an equivalent Column + Expanded(SingleChildScrollView)
/// + pinned ActionBar + bottom-nav clearance structure with a
/// parameterized fake info panel. Keeping the harness structurally
/// identical means a regression in the production layout would be
/// caught here — provided the harness gets updated in lockstep.

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

/// Mirror of `_LowerSheet`'s Column structure with a substitutable
/// info child. Keep this aligned with `_LowerSheet.build` — if you
/// restructure the production sheet, mirror the change here.
class _LowerSheetHarness extends StatelessWidget {
  final Widget infoChild;
  const _LowerSheetHarness({required this.infoChild});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimens.p24),
          topRight: Radius.circular(AppDimens.p24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppDimens.p48),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimens.p20,
                    ),
                    child: infoChild,
                  ),
                  const SizedBox(height: AppDimens.p16),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppDimens.p20),
            child: DiscoveryActionBar(
              onPass: () {},
              onUndo: () {},
              onLike: () {},
            ),
          ),
          // Mirror production: MediaQuery.padding.bottom + 12 dp gap.
          // In the test environment padding.bottom is 0, so clearance
          // is exactly 12 dp — the pinning behaviour is unchanged.
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + 12.0,
          ),
        ],
      ),
    );
  }
}

Future<void> _pumpHarness(
  WidgetTester tester, {
  required double infoHeight,
  Size? surfaceSize,
}) async {
  if (surfaceSize != null) {
    await tester.binding.setSurfaceSize(surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }
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
            body: SafeArea(
              child: _LowerSheetHarness(
                infoChild: SizedBox(
                  // Fake info panel — height is the only thing the
                  // layout cares about for these tests.
                  height: infoHeight,
                  child: const ColoredBox(color: AppColors.surface),
                ),
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

  group('lower sheet — pinned action bar', () {
    testWidgets(
        'action bar Y is identical for short vs tall info content',
        (tester) async {
      // Short info — well within the available scroll slot.
      await _pumpHarness(tester, infoHeight: 80);
      final shortBarY = tester.getTopLeft(find.byType(DiscoveryActionBar)).dy;

      // Tall info — bigger than the scroll slot, would have pushed the
      // bar off-screen under the old CustomScrollView layout.
      await _pumpHarness(tester, infoHeight: 1200);
      final tallBarY = tester.getTopLeft(find.byType(DiscoveryActionBar)).dy;

      expect(
        (shortBarY - tallBarY).abs(),
        lessThan(1.0),
        reason:
            'action bar Y must not depend on info content height',
      );
    });

    testWidgets('info panel scrolls when content is taller than the slot',
        (tester) async {
      await _pumpHarness(tester, infoHeight: 1200);

      // A Scrollable exists for the info area.
      final scrollables = find.byType(Scrollable);
      expect(scrollables, findsAtLeastNWidgets(1));

      // The action bar still sits within the visible viewport — no
      // scroll required to reach it.
      final barY = tester.getTopLeft(find.byType(DiscoveryActionBar)).dy;
      final viewportBottom = tester.view.physicalSize.height /
          tester.view.devicePixelRatio;
      expect(barY, lessThan(viewportBottom),
          reason: 'action bar must be above the viewport bottom edge');
    });

    testWidgets('action bar stays reachable on a small surface',
        (tester) async {
      // 360 × 640 — a small phone form factor.
      await _pumpHarness(
        tester,
        infoHeight: 900,
        surfaceSize: const Size(360, 640),
      );

      final barRect = tester.getRect(find.byType(DiscoveryActionBar));
      // The action bar's full visible rect is within the screen
      // (top above the screen bottom AND bottom above the screen
      // bottom — i.e., the buttons are not clipped or pushed below).
      expect(barRect.top, lessThan(640));
      expect(barRect.bottom, lessThanOrEqualTo(640),
          reason:
              'on a small screen the action bar must not be clipped '
              'below the viewport bottom');
    });
  });
}
