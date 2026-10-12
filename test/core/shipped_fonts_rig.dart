import 'dart:convert';
import 'dart:io';

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

/// Pumps [child] on a [width]-wide screen in [lang], under the app's theme
/// (which picks the face by locale) and the language's direction.
Future<void> pumpOnPhone(
  WidgetTester tester,
  String lang,
  Widget child, {
  double width = 360,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: QeranTheme.light(Locale(lang)),
      home: Directionality(
        textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr,
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

/// True when the text [text] had to cut to fit.
bool isCut(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).didExceedMaxLines;
