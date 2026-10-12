import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/theme/qeran_theme.dart';

/// For measuring whether SHIPPED copy fits its slot, at a real phone width.
///
/// The default test font draws every glyph as a full em square, which
/// overstates Arabic by about double; a width guard means nothing without the
/// shipped faces. Every weight is registered, as buttons are 600 and 700.

/// Call from `setUpAll`.
Future<void> loadShippedFonts() async {
  const weights = ['Regular', 'Medium', 'SemiBold', 'Bold'];
  for (final family in const ['NotoKufiArabic', 'Montserrat']) {
    final loader = FontLoader(family);
    for (final weight in weights) {
      loader.addFont(
        File('assets/fonts/$family-$weight.ttf').readAsBytes().then(
          (bytes) => ByteData.view(Uint8List.fromList(bytes).buffer),
        ),
      );
    }
    await loader.load();
  }
}

/// The shipped string at the dotted [path] in [lang], or null.
Object? shippedAt(String lang, String path) {
  Object? node = jsonDecode(
    File('assets/translations/$lang.json').readAsStringSync(),
  );
  for (final part in path.split('.')) {
    if (node is! Map<String, dynamic>) return null;
    node = node[part];
  }
  return node;
}

/// The shipped string at the dotted [path] in [lang].
String shipped(String lang, String path) => shippedAt(lang, path)! as String;

/// The shipped translation files, read synchronously: an awaited read does
/// not complete inside `pumpAndSettle`.
class _DiskLoader extends AssetLoader {
  const _DiskLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      jsonDecode(
            File(
              'assets/translations/${locale.languageCode}.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
}

/// Pumps [child] on a [width]-wide screen in [lang], under the app's theme
/// (which picks the face by locale) and the language's direction. With
/// [localized], inside the shipped strings too, for widgets that translate
/// their own keys — call `initShippedStrings` from `setUpAll` first.
Future<void> pumpOnPhone(
  WidgetTester tester,
  String lang,
  Widget child, {
  double width = 360,
  bool localized = false,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final home = Directionality(
    textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(body: Center(child: child)),
  );
  if (!localized) {
    await tester.pumpWidget(
      MaterialApp(theme: QeranTheme.light(Locale(lang)), home: home),
    );
    return;
  }
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      startLocale: Locale(lang),
      fallbackLocale: const Locale('ar'),
      saveLocale: false,
      path: 'assets/translations',
      assetLoader: const _DiskLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          theme: QeranTheme.light(Locale(lang)),
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: home,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// True when the text [text] had to cut to fit.
bool isCut(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).didExceedMaxLines;
