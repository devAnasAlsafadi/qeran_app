import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/utils/keyboard_dismissal.dart';

void main() {
  testWidgets('dismissKeyboard clears the currently focused text field', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TextField(focusNode: focusNode, autofocus: true)),
      ),
    );
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    await dismissKeyboard();
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
  });
}
