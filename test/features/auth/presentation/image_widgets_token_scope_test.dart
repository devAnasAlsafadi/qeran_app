import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_blurred_image.dart';
import 'package:qeran/features/likes/presentation/widgets/like_blurred_image.dart';
import 'package:qeran/features/matchmaker/shared/presentation/widgets/matchmaker_user_avatar.dart';

import 'fake_session.dart';

/// The session's token reaches our own server only, from every image widget
/// that sends it (security). The profile hero's case is in
/// `profile_screen_test.dart`.

Map<String, String>? _cached(WidgetTester tester) => tester
    .widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
    .httpHeaders;

Map<String, String>? _memoryOnly(WidgetTester tester) =>
    (tester.widget<Image>(find.byType(Image)).image as NetworkImage).headers;

/// [build] at an image on our server, then at one elsewhere, signed in.
void _scoped(
  String what,
  Widget Function(String url) build,
  Map<String, String>? Function(WidgetTester) headersOf,
) {
  Future<void> pump(WidgetTester tester, String url) => tester.pumpWidget(
    withSession(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 120, height: 120, child: build(url)),
        ),
      ),
    ),
  );

  testWidgets('$what: our server gets the token', (tester) async {
    await pump(tester, ourImageUrl);
    expect(headersOf(tester), fakeSessionBearer);
  });

  testWidgets('$what: another host gets nothing', (tester) async {
    await pump(tester, foreignImageUrl);
    expect(headersOf(tester), isNull);
  });
}

void main() {
  _scoped(
    'Discovery card photo',
    (url) => DiscoveryBlurredImage(url: url),
    _cached,
  );
  _scoped(
    'Likes photo',
    (url) => LikeBlurredImage(url: url, blur: false, size: null),
    _cached,
  );
  _scoped(
    "Likes photo, the server's blurred rendition",
    (url) => LikeBlurredImage(
      url: ourImageUrl,
      blur: true,
      blurredUrl: url,
      size: null,
    ),
    _cached,
  );
  _scoped(
    'Likes photo, held in memory only',
    (url) =>
        LikeBlurredImage(url: url, blur: false, memoryOnly: true, size: null),
    _memoryOnly,
  );
  _scoped(
    'Matchmaker avatar',
    (url) => MatchmakerUserAvatar(url: url, size: 48),
    _cached,
  );
}
