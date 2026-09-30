import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/chat/presentation/widgets/chat_input_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

Future<void> _pump(
  WidgetTester tester,
  Future<bool> Function(String) onSend,
) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: ChatInputBar(
                onSend: onSend,
                sendDisabledByCooldown: false,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _field(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

Future<void> _typeAndSend(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
  await tester.tap(find.byIcon(Icons.send_rounded));
  await tester.pump();
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('a sent message leaves the field empty', (tester) async {
    await _pump(tester, (_) async => true);

    await _typeAndSend(tester, 'Hello');

    expect(_field(tester), isEmpty);
  });

  // A rate limit never sends the message, so retyping it would be on us.
  testWidgets('a rate-limited message comes back into the field', (
    tester,
  ) async {
    final sent = <String>[];
    await _pump(tester, (text) async {
      sent.add(text);
      return false;
    });

    await _typeAndSend(tester, 'Hello');

    expect(sent, ['Hello']);
    expect(_field(tester), 'Hello');
  });

  testWidgets('what the member typed meanwhile is not overwritten', (
    tester,
  ) async {
    final outcome = Completer<bool>();
    await _pump(tester, (_) => outcome.future);
    await _typeAndSend(tester, 'Hello');

    await tester.enterText(find.byType(TextField), 'Something else');
    outcome.complete(false);
    await tester.pump();

    expect(_field(tester), 'Something else');
  });
}
