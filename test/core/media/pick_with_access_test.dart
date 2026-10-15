import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_confirm_dialog.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/media/media_access.dart';
import 'package:qeran/core/media/pick_with_access.dart';

import '../shipped_fonts_rig.dart';
import '../shipped_strings_rig.dart';
import 'media_access_rig.dart';

/// A refused camera or photo library gets one dialog in both apps: what is
/// off, how to allow it, «فتح الإعدادات» to the app's page in the phone's
/// settings and «ليس الآن». Backing out stays silent.
void main() {
  late FakeSettingsOpener settings;

  setUpAll(initShippedStrings);
  setUp(() => settings = registerFakeSettingsOpener());
  tearDown(sl.reset);

  Future<void> refuse(
    WidgetTester tester,
    String lang,
    MediaAccess access,
  ) async {
    final context = await pumpShippedStrings(tester, Locale(lang));
    pickWithAccess(context, () async => throw MediaAccessDenied(access));
    await tester.pumpAndSettle();
  }

  for (final lang in ['ar', 'en']) {
    testWidgets('$lang: the camera refused, the camera dialog', (tester) async {
      await refuse(tester, lang, MediaAccess.camera);

      expect(
        find.text(shipped(lang, 'media.camera_off_title')),
        findsOneWidget,
      );
      expect(
        find.text(shipped(lang, 'media.camera_off_message')),
        findsOneWidget,
      );
      expect(find.text(shipped(lang, 'media.open_settings')), findsOneWidget);
      expect(find.text(shipped(lang, 'media.not_now')), findsOneWidget);
      expect(find.byIcon(Icons.no_photography_outlined), findsOneWidget);
    });

    testWidgets('$lang: the photos refused, the photos dialog', (tester) async {
      await refuse(tester, lang, MediaAccess.photos);

      expect(
        find.text(shipped(lang, 'media.photos_off_title')),
        findsOneWidget,
      );
      expect(
        find.text(shipped(lang, 'media.photos_off_message')),
        findsOneWidget,
      );
      expect(find.text(shipped(lang, 'media.camera_off_title')), findsNothing);
    });
  }

  testWidgets('«فتح الإعدادات» opens the app\'s settings page', (tester) async {
    await refuse(tester, 'ar', MediaAccess.camera);

    await tester.tap(find.text(shipped('ar', 'media.open_settings')));
    await tester.pumpAndSettle();

    expect(settings.opened, 1);
    expect(find.byType(QeranConfirmDialog), findsNothing);
  });

  testWidgets('«ليس الآن» closes it; settings stay shut', (tester) async {
    await refuse(tester, 'ar', MediaAccess.photos);

    await tester.tap(find.text(shipped('ar', 'media.not_now')));
    await tester.pumpAndSettle();

    expect(settings.opened, 0);
    expect(find.byType(QeranConfirmDialog), findsNothing);
  });

  testWidgets('backing out: no dialog', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('ar'));
    var ran = false;

    await pickWithAccess(context, () async => ran = true);
    await tester.pumpAndSettle();

    expect(ran, isTrue);
    expect(find.byType(QeranConfirmDialog), findsNothing);
  });

  testWidgets('the screen already gone: no dialog, no error', (tester) async {
    final context = await pumpShippedStrings(tester, const Locale('ar'));
    final refusal = Completer<void>();
    final done = pickWithAccess(context, () => refusal.future);

    await tester.pumpWidget(const SizedBox());
    refusal.completeError(const MediaAccessDenied(MediaAccess.camera));
    await tester.pumpAndSettle();

    await expectLater(done, completes);
    expect(find.byType(QeranConfirmDialog), findsNothing);
  });
}
