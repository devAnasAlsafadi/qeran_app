import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/media_upload_outcome.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/matchmaker/community/presentation/screens/post_composer_screen.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/composer/composer_image_tile.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../community/fixtures/community_post_fixtures.dart';
import '../composer_rig.dart';
import '../publishing_rig.dart';

const _ar = Locale('ar');
const _en = Locale('en');

final _copy = {
  _ar: (
    uploading: 'جارٍ رفع المنشور… 50٪',
    cancel: 'إلغاء',
    askTitle: 'إلغاء الرفع؟',
    askBody: 'سيتوقف رفع المنشور ويعود مسودة يمكنكِ تعديلها أو تجاهلها.',
    stop: 'إلغاء الرفع',
    keep: 'متابعة الرفع',
  ),
  _en: (
    uploading: 'Uploading your post… 50%',
    cancel: 'Cancel',
    askTitle: 'Cancel upload?',
    askBody:
        'The upload stops and your post goes back to a draft you can edit or '
        'discard.',
    stop: 'Cancel upload',
    keep: 'Keep uploading',
  ),
};

/// D2 and D2b: her images going up, in both languages.
void main() {
  late ComposerHarness h;
  setUpAll(initShippedStrings);
  setUp(() => h = imageComposer());
  tearDown(() => h.guidelines.dispose());

  for (final locale in [_ar, _en]) {
    final t = _copy[locale]!;

    testWidgets('D2 [${locale.languageCode}]: «${t.uploading}», the bar and '
        '«${t.cancel}»; the draft dimmed; then made, it closes with her '
        'post', (tester) async {
      final upload = holdUpload(h);
      h.publishes(Right(PostPublished(testPost(id: 31))));
      await publishWithImage(tester, h, locale: locale);

      expect(find.text(t.uploading), findsOneWidget);
      expect(find.text(t.cancel), findsOneWidget);
      final dimmed = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(dimmed.where((o) => o.opacity == 0.5), isNotEmpty);

      upload.complete(const Right(MediaUploaded('m-1')));
      await tester.pumpAndSettle();
      expect(h.result?.id, 31);
      expect(h.publishing.lastImageIds(), ['m-1']);
    });

    testWidgets('D2b [${locale.languageCode}]: × asks; «${t.keep}» goes on, '
        '«${t.stop}» returns the draft', (tester) async {
      holdUpload(h);
      await publishWithImage(tester, h, locale: locale);

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await frames(tester);
      expect(find.text(t.askTitle), findsOneWidget);
      expect(find.text(t.askBody), findsOneWidget);
      await tester.tap(find.text(t.keep));
      await frames(tester);
      expect(find.text(t.uploading), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await frames(tester);
      await tester.tap(find.text(t.stop));
      await tester.pumpAndSettle();
      expect(find.byType(PostComposerScreen), findsOneWidget);
      expect(find.text(t.uploading), findsNothing);
      expect(find.byType(ComposerImageTile), findsOneWidget);
      expect(h.sentIds, isEmpty);
    });
  }

  testWidgets('the strip\'s «Cancel» stops it without asking', (tester) async {
    holdUpload(h);
    await publishWithImage(tester, h);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel upload?'), findsNothing);
    expect(find.text('Uploading your post… 50%'), findsNothing);
    expect(h.sentIds, isEmpty);
  });
}
