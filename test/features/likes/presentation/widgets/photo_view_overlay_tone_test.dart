import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/features/likes/presentation/blocs/photo_view_state.dart';
import 'package:qeran/features/likes/presentation/widgets/photo_view_access_host.dart';
import 'package:qeran/features/likes/presentation/widgets/photo_view_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The overlay sits inside the paper gallery sheet, and paints no background
// of its own in any phase. A full-bleed scrim tinted the whole card — wine
// washed it mauve, cream washed it beige — and either way the sheet stopped
// reading as white paper holding photo tiles.

/// Loads the real translations synchronously — an awaited file read does not
/// complete inside pumpAndSettle, so the tree would still be EasyLocalization's
/// placeholder when the assertion runs and nothing would be found at all.
class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final file = File('assets/translations/${locale.languageCode}.json');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await EasyLocalization.ensureInitialized();
  });

  Future<void> pump(WidgetTester tester, PhotoViewPhase phase) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        path: 'assets/translations',
        startLocale: const Locale('ar'),
        assetLoader: const _DiskAssetLoader(),
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(
              // The paper sheet the overlay is painted onto.
              body: ColoredBox(
                color: QeranColors.paper,
                child: Stack(
                  children: [
                    PhotoViewScope(
                      state: PhotoViewState(phase: phase),
                      onReveal: () {},
                      onRetry: () {},
                      onImageForbidden: () {},
                      child: const PhotoViewOverlay(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // Bounded pumps, not pumpAndSettle: the loading phase shows QeranLoader,
    // which repeats forever, so settling would never return. Two frames is
    // enough for the synchronous translation load to land.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  /// Fills painted BY the overlay — the surrounding paper sheet in this
  /// harness is not one of them.
  List<Color> fills(WidgetTester tester) => tester
      .widgetList<ColoredBox>(
        find.descendant(
          of: find.byType(PhotoViewOverlay),
          matching: find.byType(ColoredBox),
        ),
      )
      .map((w) => w.color)
      .toList();

  for (final phase in [
    PhotoViewPhase.available,
    PhotoViewPhase.consumed,
    PhotoViewPhase.failure,
    PhotoViewPhase.loading,
  ]) {
    testWidgets('$phase tints nothing over the sheet', (tester) async {
      await pump(tester, phase);

      expect(
        fills(tester),
        isEmpty,
        reason: 'the card stays white; the state is carried by the control '
            'itself, not by a wash over the photo tiles',
      );
    });
  }

  testWidgets('an open window covers the photos with nothing at all', (
    tester,
  ) async {
    await pump(tester, PhotoViewPhase.viewing);

    expect(fills(tester), isEmpty);
  });

  testWidgets('no accepted exchange renders nothing', (tester) async {
    await pump(tester, PhotoViewPhase.unavailable);

    expect(fills(tester), isEmpty);
  });
}
