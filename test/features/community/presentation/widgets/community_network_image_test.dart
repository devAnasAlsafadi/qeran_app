import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/features/community/presentation/widgets/community_network_image.dart';

import '../../../../core/shipped_strings_rig.dart';
import '../../../auth/presentation/fake_session.dart';
import '../../fixtures/community_post_fixtures.dart';

const _relative = '/api/community/media/m-1';

Future<void> _pump(WidgetTester tester, Widget image) => pumpShippedStrings(
  tester,
  const Locale('en'),
  child: withSession(SizedBox(width: 334, height: 188, child: image)),
);

CachedNetworkImage _network(WidgetTester tester) =>
    tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));

/// What the image shows when its load fails. (In tests the cache never gets
/// that far — it has no file system — so the failure is asked for directly.)
Widget _onError(WidgetTester tester) => _network(tester).errorWidget!(
  tester.element(find.byType(CachedNetworkImage)),
  _network(tester).imageUrl,
  Exception('404'),
);

void main() {
  setUpAll(initShippedStrings);

  testWidgets('a post image: resolved on our server, sent with the token', (
    tester,
  ) async {
    await _pump(tester, const CommunityNetworkImage(_relative));

    expect(_network(tester).imageUrl, EndPoints.absoluteUrl(_relative));
    expect(_network(tester).httpHeaders, fakeSessionBearer);
  });

  testWidgets('a signed video poster: as given, with no token', (tester) async {
    await _pump(tester, const CommunityNetworkImage(signedPoster));

    expect(_network(tester).imageUrl, signedPoster);
    expect(_network(tester).httpHeaders, isNull);
  });

  testWidgets('a failure offers a retry, and a retry asks again (A8)', (
    tester,
  ) async {
    await _pump(tester, const CommunityNetworkImage(_relative));
    final firstRequest = _network(tester).key;

    final failed = _onError(tester) as CommunityImageFailed;
    failed.onRetry();
    await tester.pump();

    expect(_network(tester).key, isNot(firstRequest));
  });

  testWidgets('the failed state: icon, message, Try again', (tester) async {
    var retries = 0;
    await _pump(tester, CommunityImageFailed(onRetry: () => retries++));

    expect(find.byIcon(Icons.broken_image_rounded), findsOneWidget);
    expect(find.text("Couldn't load the image"), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retries, 1);
  });

  testWidgets('with a fallback, a failure shows the fallback instead', (
    tester,
  ) async {
    const fallback = SizedBox(key: Key('fallback'));
    await _pump(
      tester,
      const CommunityNetworkImage(_relative, fallback: fallback),
    );

    expect(_onError(tester), same(fallback));
  });

  testWidgets('no URL at all: the failed state at once', (tester) async {
    await _pump(tester, const CommunityNetworkImage(' '));

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byType(CommunityImageFailed), findsOneWidget);
  });
}
