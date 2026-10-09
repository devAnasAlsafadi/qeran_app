import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/community/domain/entities/media_refusal.dart';
import 'package:qeran/features/community/domain/entities/media_upload_outcome.dart';
import 'package:qeran/features/community/domain/entities/post_publish_outcome.dart';
import 'package:qeran/features/matchmaker/community/presentation/widgets/composer/composer_image_tile.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../community/fixtures/community_post_fixtures.dart';
import '../composer_media_fakes.dart';
import '../composer_rig.dart';
import '../publishing_rig.dart';

/// What the server says to a post with images (plan §3.4's table).
void main() {
  late ComposerHarness h;
  setUpAll(initShippedStrings);
  setUp(() => h = imageComposer());
  tearDown(() => h.guidelines.dispose());

  testWidgets('D3: the upload fails — the failed strip; Retry goes on and '
      'makes one post', (tester) async {
    final upload = holdUpload(h);
    await publishWithImage(tester, h);
    upload.complete(const Left(OfflineFailure()));
    await tester.pumpAndSettle();
    expect(
      find.text("Couldn't upload your post. Check your connection."),
      findsOneWidget,
    );

    h.publishing.uploads('a.jpg');
    h.publishes(Right(PostPublished(testPost(id: 31))));
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(h.result?.id, 31);
    expect(h.sentIds, ['req-1']);
  });

  testWidgets('the server refuses the image\'s size: it leaves, and Q3 says '
      'why', (tester) async {
    h.inspector.files['a.jpg'] = jpeg('a.jpg', size: 3145728);
    h.publishing.uploads(
      'a.jpg',
      const Right(MediaUploadRefused(MediaRefusal.tooLarge)),
    );
    await publishWithImage(tester, h);
    await tester.pumpAndSettle();

    expect(find.byType(ComposerImageTile), findsNothing);
    expect(
      find.text(
        'This image is 3 MB, over the 5 MB limit. Choose another image.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('C7 from the server: the limits are read again, and the '
      'failed strip', (tester) async {
    h.publishes(const Right(PostTextInvalid()));
    await startComposer(tester, h);
    await tester.enterText(find.byType(TextField), 'إرشاد');
    await tester.pump();
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);
    verify(() => h.config(fresh: true)).called(2);
  });
}
