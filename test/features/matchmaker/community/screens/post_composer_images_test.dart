import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_config.dart';
import 'package:qeran/features/matchmaker/community/presentation/services/community_media_picker.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/composer/composer_image_tile.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../composer_media_fakes.dart';
import '../composer_rig.dart';

const _ar = Locale('ar');
const _en = Locale('en');

final _copy = {
  _ar: (
    images: 'صور',
    sheet: 'إضافة صور',
    gallery: 'اختيار من المعرض',
    camera: 'التقاط صورة',
    note: 'حتى 10 صور في المنشور. تُفتح كاميرا الهاتف نفسها.',
    reorder: ' · اسحبي لتغيير الترتيب',
    tooMany: 'أُضيفت أول 3 صور من 5 اخترتِها. الحد الأقصى 3 صور في المنشور.',
    unsupported: 'نوع هذا الملف غير مدعوم. استخدمي صور JPG أو PNG.',
    tooLarge:
        'حجم هذه الصورة 6 ميغابايت، وهو أكبر من الحد المسموح (5 ميغابايت). '
        'اختاري صورة أخرى.',
    cameraDenied:
        'لا يمكن فتح الكاميرا دون إذنكِ. يمكنكِ تفعيله من إعدادات الهاتف.',
  ),
  _en: (
    images: 'Images',
    sheet: 'Add images',
    gallery: 'Choose from gallery',
    camera: 'Take a photo',
    note: "Up to 10 images per post. Opens the phone's own camera.",
    reorder: ' · Drag to reorder',
    tooMany:
        'The first 3 of the 5 images you picked were added. A post can have '
        'up to 3 images.',
    unsupported: "This file type isn't supported. Use JPG or PNG images.",
    tooLarge: 'This image is 6 MB, over the 5 MB limit. Choose another image.',
    cameraDenied:
        "The camera can't open without your permission. You can turn it on "
        "in the phone's settings.",
  ),
};

/// Each thumbnail's ×.
final _removeButtons = find.descendant(
  of: find.byType(ComposerImageTile),
  matching: find.byType(InkResponse),
);

const _limits = CommunityConfig(
  postTextMaxLength: 2000,
  maxImagesPerPost: 10,
  maxImageSizeBytes: 5242880,
  allowedImageTypes: ['jpg', 'jpeg', 'png'],
);

void main() {
  late ComposerHarness h;
  setUpAll(initShippedStrings);
  setUp(() => h = ComposerHarness()..configure(_limits));
  tearDown(() => h.guidelines.dispose());

  Future<void> sheet(WidgetTester tester, String images) async {
    await tester.tap(find.text(images).last);
    await tester.pumpAndSettle();
  }

  Future<void> pick(WidgetTester tester, String source) async {
    await tester.tap(find.text(source));
    await tester.pumpAndSettle();
  }

  for (final locale in [_ar, _en]) {
    final t = _copy[locale]!;

    testWidgets('C3, C5 [${locale.languageCode}]: «${t.sheet}» with its '
        'note; the gallery is told the free slots; her images in her order '
        'under «${t.images}» with the count', (tester) async {
      h.picker.gallery = ['b.jpg', 'a.jpg'];
      await startComposer(tester, h, locale: locale);

      await sheet(tester, t.images);
      expect(find.text(t.sheet), findsOneWidget);
      expect(find.text(t.note), findsOneWidget);
      await pick(tester, t.gallery);

      expect(h.picker.limits, [10]);
      final tiles = tester.widgetList<ComposerImageTile>(
        find.byType(ComposerImageTile),
      );
      expect([for (final tile in tiles) tile.path], ['b.jpg', 'a.jpg']);
      expect(find.text('2 / 10'), findsOneWidget);
      expect(find.text(t.reorder), findsOneWidget);
    });

    testWidgets('C8 [${locale.languageCode}]: more than fit — the first ones, '
        'and the gold notice', (tester) async {
      h.configure(
        const CommunityConfig(postTextMaxLength: 2000, maxImagesPerPost: 3),
      );
      h.picker.gallery = ['1.jpg', '2.jpg', '3.jpg', '4.jpg', '5.jpg'];
      await startComposer(tester, h, locale: locale);

      await sheet(tester, t.images);
      await pick(tester, t.gallery);

      expect(find.byType(ComposerImageTile), findsNWidgets(3));
      expect(find.text(t.tooMany), findsOneWidget);
    });

    testWidgets('C10, Q3 [${locale.languageCode}]: a type or a size the server '
        'wouldn\'t take stays out, and says why', (tester) async {
      h.inspector.files['x.gif'] = null;
      h.inspector.files['big.jpg'] = jpeg('big.jpg', size: 6291456);
      await startComposer(tester, h, locale: locale);

      h.picker.gallery = ['x.gif'];
      await sheet(tester, t.images);
      await pick(tester, t.gallery);
      expect(find.text(t.unsupported), findsOneWidget);

      h.picker.gallery = ['big.jpg'];
      await sheet(tester, t.images);
      await pick(tester, t.gallery);
      expect(find.text(t.tooLarge), findsOneWidget);
      expect(find.byType(ComposerImageTile), findsNothing);
    });

    testWidgets('S9 [${locale.languageCode}]: the camera refused — a calm '
        'toast, nothing added', (tester) async {
      h.picker.refuses = const MediaAccessDenied(MediaAccess.camera);
      await startComposer(tester, h, locale: locale);

      await sheet(tester, t.images);
      await pick(tester, t.camera);

      expect(find.text(t.cameraDenied), findsOneWidget);
      expect(find.byType(ComposerImageTile), findsNothing);
      await tester.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('the camera adds one; × removes it', (tester) async {
    h.picker.camera = 'cam.jpg';
    await startComposer(tester, h);

    await sheet(tester, 'Images');
    await pick(tester, 'Take a photo');
    expect(find.byType(ComposerImageTile), findsOneWidget);
    expect(find.text(' · Drag to reorder'), findsNothing);

    expect(find.bySemanticsLabel('Remove image'), findsOneWidget);
    await tester.tap(_removeButtons);
    await tester.pumpAndSettle();
    expect(find.byType(ComposerImageTile), findsNothing);
  });

  testWidgets('full: «Images» dims and no add tile; one removed, both '
      'return', (tester) async {
    h.configure(
      const CommunityConfig(postTextMaxLength: 2000, maxImagesPerPost: 2),
    );
    h.picker.gallery = ['a.jpg', 'b.jpg'];
    await startComposer(tester, h);
    await sheet(tester, 'Images');
    await pick(tester, 'Choose from gallery');

    expect(find.text('Add'), findsNothing);
    final dimmed = find.ancestor(
      of: find.text('Images').last,
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(dimmed.first).opacity, 0.4);

    await tester.tap(_removeButtons.first);
    await tester.pumpAndSettle();
    expect(find.text('Add'), findsOneWidget);
    expect(tester.widget<Opacity>(dimmed.first).opacity, 1);
  });
}
