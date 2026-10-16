import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_confirm_dialog.dart';

import '../shipped_strings_rig.dart';

/// Overlays are dark wine, never Flutter's default black (cleanup audit `19`,
/// run 11): every dialog and sheet passes `QeranColors.overlayTintDark`.
void main() {
  setUpAll(initShippedStrings);

  final call = RegExp(
    r'\b(showDialog|showModalBottomSheet|showGeneralDialog)\s*(<[^>(]*>)?\s*\(',
  );

  /// The argument list of the call whose `(` is at [open].
  String argsAt(String text, int open) {
    var depth = 0;
    for (var i = open; i < text.length; i++) {
      if (text[i] == '(') depth++;
      if (text[i] == ')' && --depth == 0) return text.substring(open, i + 1);
    }
    return text.substring(open);
  }

  test('every dialog and sheet in lib/ passes the wine barrier', () {
    final missing = <String>[];
    var calls = 0;
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final text = file.readAsStringSync();
      for (final m in call.allMatches(text)) {
        calls++;
        final args = argsAt(text, m.end - 1);
        if (!args.contains('barrierColor: QeranColors.overlayTintDark')) {
          final line = '\n'.allMatches(text.substring(0, m.start)).length + 1;
          missing.add('${file.path}:$line');
        }
      }
    }
    expect(calls, greaterThan(10));
    expect(missing, isEmpty);
  });

  testWidgets('a confirm dialog dims in wine', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('ar'));
    QeranConfirmDialog.show(
      context,
      title: 'T',
      message: 'M',
      confirmLabel: 'OK',
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (w) => w is ModalBarrier && w.color == QeranColors.overlayTintDark,
      ),
      findsOneWidget,
    );
  });
}
