import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';

import '../shipped_fonts_rig.dart';

/// Run 6: no button label is ever cut, in either language, on a 360-wide
/// phone. Measured in the shipped fonts, slot by slot.
///
/// - `button_slots.json`: every place a `QeranButton` sits — its key, its
///   width at 360 (the screen less every padding around it), size and icons.
///   A button wraps rather than cuts (`qeran_button_wrap_test.dart`); this
///   fails when one needs more than two lines.
/// - `tappable_labels.json`: tabs, rows, pills and links that still cut —
///   their key, the room their label gets, its style and lines. This fails on
///   any that is cut.
///
/// It measures slots, not screens: a padding change around a button must
/// update its width here. A new button can't slip past unmeasured — the scan
/// at the end fails on any label key under `lib/` that the table lacks.

List<Map<String, dynamic>> _table(String name) =>
    (jsonDecode(File('test/core/copy/$name').readAsStringSync())
            as List<dynamic>)
        .cast<Map<String, dynamic>>();

/// A label as a member sees it: arguments filled with a two-digit number.
String _text(String lang, String key) =>
    shipped(lang, key).replaceAll(RegExp(r'\{[^}]*\}'), '12');

QeranButtonSize _size(Object? name) => switch (name) {
  'md' => QeranButtonSize.md,
  'compact' => QeranButtonSize.compact,
  _ => QeranButtonSize.lg,
};

TextStyle _style(Map<String, dynamic> row) {
  final base = switch (row['style']) {
    'caption' => QeranTypography.caption,
    'label' => QeranTypography.label,
    'body' => QeranTypography.body,
    'bodySm' => QeranTypography.bodySm,
    _ => QeranTypography.subtitle,
  };
  final weight = row['weight'] as int?;
  return base.copyWith(
    fontSize: (row['fontSize'] as num?)?.toDouble(),
    fontWeight: weight == null ? null : FontWeight.values[weight ~/ 100 - 1],
  );
}

/// How many lines [text]'s paragraph took.
int _lines(WidgetTester tester, String text) {
  final p = tester.renderObject<RenderParagraph>(find.text(text));
  return (p.size.height / p.getMaxIntrinsicHeight(double.infinity)).round();
}

void main() {
  setUpAll(loadShippedFonts);

  for (final lang in const ['ar', 'en']) {
    testWidgets('every button label is whole, on at most two lines [$lang]', (
      tester,
    ) async {
      final tooLong = <String>[];
      for (final row in _table('button_slots.json')) {
        final text = _text(lang, row['key'] as String);
        await pumpOnPhone(
          tester,
          lang,
          SizedBox(
            width: (row['width'] as num).toDouble(),
            child: QeranButton(
              label: text,
              onPressed: () {},
              size: _size(row['size']),
              leadingIcon: row['lead'] == true ? Icons.add : null,
              trailingIcon: row['trail'] == true ? Icons.add : null,
            ),
          ),
        );
        final lines = _lines(tester, text);
        if (isCut(tester, text) || lines > 2) {
          tooLong.add('${row['site']} ${row['key']}: $lines');
        }
      }
      expect(tooLong, isEmpty);
    });

    testWidgets('no tab, row, pill or link label is cut [$lang]', (
      tester,
    ) async {
      final cut = <String>[];
      for (final row in _table('tappable_labels.json')) {
        final text = _text(lang, row['key'] as String);
        await pumpOnPhone(
          tester,
          lang,
          SizedBox(
            width: (row['width'] as num).toDouble(),
            child: Text(
              text,
              style: _style(row),
              maxLines: row['lines'] as int? ?? 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
        if (isCut(tester, text)) cut.add('${row['site']} ${row['key']}');
      }
      expect(cut, isEmpty);
    });
  }

  test('every button label under lib/ is measured here', () {
    final measured = {
      for (final row in _table('button_slots.json')) row['key'] as String,
    };
    expect(
      buttonLabelKeysInLib().difference(measured).difference(_notButtons),
      isEmpty,
    );
  });
}

/// Caught by the scan's `actionLabel:` but no button's: the attention card's
/// own action text, which wraps.
const _notButtons = {'matchmaker.dashboard_hero_action'};

/// `LocaleKeys` constant names to their dotted keys.
Map<String, String> _localeKeys() => {
  for (final m in RegExp(
    r"static const (\w+) = '([^']+)';",
  ).allMatches(File('lib/generated/locale_keys.g.dart').readAsStringSync()))
    m.group(1)!: m.group(2)!,
};

/// Every key a `QeranButton` label is built from, directly or through the
/// wrappers that hand theirs to one.
Set<String> buttonLabelKeysInLib() {
  final names = _localeKeys();
  final label = RegExp(
    r'(?:QeranButton\(\s*(?:key: [^,]+,\s*)?label|retryLabel|actionLabel|'
    r'secondaryActionLabel|primaryLabel|MatchmakerPrimaryAction\(\s*label)'
    r':\s*([^;]*?)(?:,\n|\)\n)',
  );
  final keys = <String>{};
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.contains('generated'));
  for (final file in files) {
    for (final m in label.allMatches(file.readAsStringSync())) {
      for (final k in RegExp(r'LocaleKeys\.(\w+)').allMatches(m.group(1)!)) {
        keys.add(names[k.group(1)]!);
      }
    }
  }
  return keys;
}
