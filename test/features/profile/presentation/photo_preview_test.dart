import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/profile/domain/entities/photo_slot.dart';
import 'package:qeran/features/profile/domain/entities/profile_image.dart';
import 'package:qeran/features/profile/presentation/screens/photo_manager/widgets/filled_photo_slot.dart';
import 'package:qeran/features/profile/presentation/screens/photo_manager/widgets/photo_preview_screen.dart';

/// QER-77: a filled thumbnail opens the photo full-screen.
///
/// The delicate part is that ONE thumbnail now carries three gestures — open
/// the preview, delete, and set-primary. Set-primary used to own the entire
/// slot as a full-bleed scrim, so these tests exist mainly to prove the two
/// small corner controls still win their own taps instead of being swallowed
/// by the preview target underneath them.

/// A real on-disk file — `Image.file` needs a path that exists, and the widget
/// keys its Hero tag off that path.
late Directory _tempDir;
late File _photo;

/// Every slot below uses `isPrimary: false`: the primary badge resolves a
/// locale key, and standing up EasyLocalization would add nothing here — the
/// badge is unchanged by QER-77 and both corner controls render regardless.

Widget _host(Widget child, {required TextDirection direction}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: Center(
          child: SizedBox(width: 160, height: 200, child: child),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    _tempDir = Directory.systemTemp.createTempSync('qeran_photo_test');
    _photo = File('${_tempDir.path}/photo.png')
      // A 1x1 transparent PNG — decodable, so Image.file does not throw.
      ..writeAsBytesSync(<int>[
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);
  });

  tearDownAll(() => _tempDir.deleteSync(recursive: true));

  for (final direction in [TextDirection.rtl, TextDirection.ltr]) {
    final lang = direction == TextDirection.rtl ? 'ar' : 'en';

    testWidgets('tapping the photo opens the preview [$lang]', (tester) async {
      var removed = false;
      var madePrimary = false;

      await tester.pumpWidget(
        _host(
          FilledPhotoSlot(
            slot: StagedPhotoSlot(path: _photo.path, isMain: false),
            isBusy: false,
            onRemove: () => removed = true,
            onSetPrimary: () => madePrimary = true,
          ),
          direction: direction,
        ),
      );

      // Centre of the thumbnail — clear of both corner controls.
      await tester.tap(find.byType(FilledPhotoSlot));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoPreviewScreen), findsOneWidget);
      // The preview must not have been mistaken for either corner action.
      expect(removed, isFalse);
      expect(madePrimary, isFalse);
    });

    testWidgets('the delete x deletes and does not preview [$lang]', (
      tester,
    ) async {
      var removed = false;

      await tester.pumpWidget(
        _host(
          FilledPhotoSlot(
            slot: StagedPhotoSlot(path: _photo.path, isMain: false),
            isBusy: false,
            onRemove: () => removed = true,
            onSetPrimary: () {},
          ),
          direction: direction,
        ),
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(removed, isTrue);
      expect(find.byType(PhotoPreviewScreen), findsNothing);
    });

    testWidgets('the set-primary check acts and does not preview [$lang]', (
      tester,
    ) async {
      var madePrimary = false;

      await tester.pumpWidget(
        _host(
          FilledPhotoSlot(
            slot: StagedPhotoSlot(path: _photo.path, isMain: false),
            isBusy: false,
            onRemove: () {},
            onSetPrimary: () => madePrimary = true,
          ),
          direction: direction,
        ),
      );

      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pumpAndSettle();

      expect(madePrimary, isTrue);
      expect(find.byType(PhotoPreviewScreen), findsNothing);
    });
  }

  testWidgets('preview shows the whole photo and can zoom', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: PhotoPreviewScreen(file: _photo)),
    );
    await tester.pumpAndSettle();

    // contain, never cover — a cropped check is not a check.
    final image = tester.widget<Image>(find.byType(Image));
    expect(image.fit, BoxFit.contain);

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(viewer.maxScale, greaterThan(1));
  });

  testWidgets('preview closes on a tap and on the x', (tester) async {
    for (final closeByIcon in [false, true]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => PhotoPreviewScreen.open(context, _photo),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.byType(PhotoPreviewScreen), findsOneWidget);

      await tester.tap(
        closeByIcon
            ? find.byIcon(Icons.close_rounded)
            : find.byType(InteractiveViewer),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PhotoPreviewScreen), findsNothing);
    }
  });

  testWidgets('thumbnail and preview share one hero tag', (tester) async {
    await tester.pumpWidget(
      _host(
        FilledPhotoSlot(
            slot: StagedPhotoSlot(path: _photo.path, isMain: false),
            isBusy: false,
          onRemove: () {},
          onSetPrimary: () {},
        ),
        direction: TextDirection.ltr,
      ),
    );

    final hero = tester.widget<Hero>(find.byType(Hero));
    // Keyed on the path, not the index — removing a photo re-indexes the
    // remaining slots and an index tag would fly the wrong image.
    expect(hero.tag, uploadPhotoHeroTag(_photo.path));
  });

  testWidgets('a still-uploading slot does not open the preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FilledPhotoSlot(
            slot: StagedPhotoSlot(path: _photo.path, isMain: false),
            isBusy: true,
          onRemove: () {},
          onSetPrimary: () {},
        ),
        direction: TextDirection.ltr,
      ),
    );

    await tester.tap(find.byType(FilledPhotoSlot));
    await tester.pumpAndSettle();

    expect(find.byType(PhotoPreviewScreen), findsNothing);
  });

  // Issue 2: the unified screen must preview server photos too, not just
  // freshly staged files. profileEdit shows only server slots, so without
  // this the QER-77 behaviour is dead on that mode.
  group('server photos', () {
    const slot = ServerPhotoSlot(
      OwnerImage(
        id: 'img-1',
        url: 'https://cdn.test/img-1.jpg',
        isProfile: false,
      ),
    );

    testWidgets('tapping a server thumbnail opens the preview', (tester) async {
      var removed = false;
      var madePrimary = false;

      await tester.pumpWidget(
        _host(
          FilledPhotoSlot(
            slot: slot,
            isBusy: false,
            onRemove: () => removed = true,
            onSetPrimary: () => madePrimary = true,
          ),
          direction: TextDirection.ltr,
        ),
      );

      await tester.tap(find.byType(FilledPhotoSlot));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(PhotoPreviewScreen), findsOneWidget);
      expect(removed, isFalse);
      expect(madePrimary, isFalse);
    });

    testWidgets('the delete x still wins its own tap', (tester) async {
      var removed = false;

      await tester.pumpWidget(
        _host(
          FilledPhotoSlot(
            slot: slot,
            isBusy: false,
            onRemove: () => removed = true,
            onSetPrimary: () {},
          ),
          direction: TextDirection.ltr,
        ),
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(removed, isTrue);
      expect(find.byType(PhotoPreviewScreen), findsNothing);
    });

    testWidgets('the set-main check still wins its own tap', (tester) async {
      var madePrimary = false;

      await tester.pumpWidget(
        _host(
          FilledPhotoSlot(
            slot: slot,
            isBusy: false,
            onRemove: () {},
            onSetPrimary: () => madePrimary = true,
          ),
          direction: TextDirection.ltr,
        ),
      );

      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pump();

      expect(madePrimary, isTrue);
      expect(find.byType(PhotoPreviewScreen), findsNothing);
    });

    testWidgets('thumbnail and preview share the id-keyed hero tag', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FilledPhotoSlot(
            slot: slot,
            isBusy: false,
            onRemove: () {},
            onSetPrimary: () {},
          ),
          direction: TextDirection.ltr,
        ),
      );

      final hero = tester.widget<Hero>(find.byType(Hero));
      // Keyed on the stable id, not the URL — a re-signed URL must not
      // break the flight.
      expect(hero.tag, serverPhotoHeroTag('img-1'));
    });
  });
}
