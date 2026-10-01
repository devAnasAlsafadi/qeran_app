import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_privacy_message.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Strings render as their keys.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

const _caption = 'discovery.privacy_message';
const _white = Color(0xFFFFFFFF);

/// WCAG contrast ratio between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

Future<void> _pump(
  WidgetTester tester, {
  required Locale locale,
  double width = 375,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: [locale],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          // The lightest photo there is.
          home: ColoredBox(
            color: _white,
            child: Center(
              child: SizedBox(
                width: width,
                child: const DiscoveryPrivacyMessage(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color _fillBehind(WidgetTester tester, Finder child) {
  final box = tester.widget<DecoratedBox>(
    find.ancestor(of: child, matching: find.byType(DecoratedBox)).first,
  );
  return switch (box.decoration) {
    BoxDecoration(:final color) => color!,
    ShapeDecoration(:final color) => color!,
    _ => throw StateError('unexpected decoration ${box.decoration}'),
  };
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final locale in const [Locale('ar'), Locale('en')]) {
    final lang = locale.languageCode;

    // Measured against pure white, without the wine tint the photo adds
    // underneath: the message must hold up on its own, whatever is behind it.
    testWidgets('the caption reads on a white photo [$lang]', (tester) async {
      await _pump(tester, locale: locale);

      final caption = find.text(_caption);
      final ink = tester.widget<Text>(caption).style!.color!;
      final backing = Color.alphaBlend(_fillBehind(tester, caption), _white);
      expect(
        _contrast(ink, backing),
        greaterThanOrEqualTo(4.5),
        reason: 'small text needs 4.5:1 (WCAG AA) — on any photo',
      );
    });

    testWidgets('the lock reads on a white photo [$lang]', (tester) async {
      await _pump(tester, locale: locale);

      final lock = find.byIcon(Icons.lock_outline_rounded);
      final ink = tester.widget<Icon>(lock).color!;
      final disc = Color.alphaBlend(_fillBehind(tester, lock), _white);
      expect(
        _contrast(ink, disc),
        greaterThanOrEqualTo(3),
        reason: 'an icon needs 3:1 (WCAG non-text contrast) — on any photo',
      );
    });

    testWidgets('a wrapped caption keeps every corner on its backing [$lang]', (
      tester,
    ) async {
      await _pump(tester, locale: locale, width: 220, textScale: 2);

      final caption = find.text(_caption);
      final lines = tester
          .renderObject<RenderParagraph>(caption)
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: _caption.length),
          )
          .map((box) => box.top)
          .toSet()
          .length;
      // The case being guarded only exists once the caption wraps.
      expect(lines, greaterThanOrEqualTo(3));

      final backingFinder = find
          .ancestor(of: caption, matching: find.byType(DecoratedBox))
          .first;
      final shape =
          (tester.widget<DecoratedBox>(backingFinder).decoration
                  as ShapeDecoration)
              .shape;
      final outline = shape.getOuterPath(tester.getRect(backingFinder));
      final text = tester.getRect(caption);
      for (final corner in [
        text.topLeft,
        text.topRight,
        text.bottomLeft,
        text.bottomRight,
      ]) {
        expect(
          outline.contains(corner),
          isTrue,
          reason: 'the text box corner $corner falls off the backing $outline',
        );
      }
    });
  }
}
