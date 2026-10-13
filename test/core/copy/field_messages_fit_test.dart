import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_helper_line.dart';
import 'package:qeran/core/design_system/widgets/qeran_text_field.dart';

import '../shipped_fonts_rig.dart';

/// Run 7 (Anas's hand check): no message in or under a field is ever cut, in
/// either app or language, on a 360-wide phone — the label guard
/// (`button_labels_fit_test.dart`) extended to fields.
///
/// `field_messages.json`: every error, hint and help line a field shows — its
/// key, its kind, and the room its field gets at 360 (never more than it
/// really has). Each is drawn in a `QeranTextField` of that width, in the
/// shipped fonts, and fails if it ends in "…" or is cut.
///
/// A new message can't slip past unmeasured: the scan at the end fails on any
/// hint, help line or validator message under `lib/` the table lacks. Errors a
/// screen sets through a variable (a cubit's answer) are listed by hand.

List<Map<String, dynamic>> _table() =>
    (jsonDecode(File('test/core/copy/field_messages.json').readAsStringSync())
            as List<dynamic>)
        .cast<Map<String, dynamic>>();

/// A message as a member sees it: arguments filled with a two-digit number.
String _text(String lang, String key) =>
    shipped(lang, key).replaceAll(RegExp(r'\{[^}]*\}'), '12');

Widget _field(TextEditingController controller, String kind, String text) =>
    switch (kind) {
      'hint' => QeranTextField(controller: controller, hint: text),
      'helper' => QeranTextField(
        controller: controller,
        helper: QeranHelperLine(icon: Icons.info_outline, text: text),
      ),
      _ => QeranTextField(controller: controller, errorText: text),
    };

void main() {
  setUpAll(loadShippedFonts);

  for (final lang in const ['ar', 'en']) {
    testWidgets('every field message is whole at 360 [$lang]', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final cut = <String>[];
      for (final row in _table()) {
        final text = _text(lang, row['key'] as String);
        await pumpOnPhone(
          tester,
          lang,
          SizedBox(
            width: (row['width'] as num).toDouble(),
            child: _field(controller, row['kind'] as String, text),
          ),
        );
        if (isCut(tester, text)) cut.add('${row['site']} ${row['key']}');
      }
      expect(cut, isEmpty);
    });
  }

  test('every field message under lib/ is measured here', () {
    final measured = {for (final row in _table()) row['key'] as String};
    expect(
      fieldMessageKeysInLib().difference(measured).difference(_notFields),
      isEmpty,
    );
  });
}

/// Caught by the scan, but not a single-line field's: a card's own `hint:`
/// argument, and the two composers, which are multi-line and already wrap.
const _notFields = {
  'likes.matches_journey_view',
  'chat.composer_placeholder',
  'matchmaker.community.composer_hint',
};

/// Every validator message, and every key handed to a field as its hint or
/// to a help line as its text.
Set<String> fieldMessageKeysInLib() {
  final names = {
    for (final m in RegExp(
      r"static const (\w+) = '([^']+)';",
    ).allMatches(File('lib/generated/locale_keys.g.dart').readAsStringSync()))
      m.group(1)!: m.group(2)!,
  };
  final keys = names.values.where((k) => k.startsWith('validators.')).toSet()
    ..remove('validators');
  final patterns = [
    RegExp(r'\bhint(?:Text)?\s*[:=]\s*LocaleKeys\.(\w+)'),
    RegExp(r'QeranHelperLine\([^;]*?text:\s*LocaleKeys\.(\w+)'),
  ];
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('generated'));
  for (final file in files) {
    final source = file.readAsStringSync();
    for (final pattern in patterns) {
      for (final m in pattern.allMatches(source)) {
        keys.add(names[m.group(1)]!);
      }
    }
  }
  return keys;
}
