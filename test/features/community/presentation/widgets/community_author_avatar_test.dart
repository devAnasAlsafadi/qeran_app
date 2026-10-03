import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/design_system/widgets/qeran_monogram.dart';
import 'package:qeran/features/community/domain/entities/community_author.dart';
import 'package:qeran/features/community/presentation/widgets/community_author_avatar.dart';

import '../../../auth/presentation/fake_session.dart';
import '../../fixtures/community_post_fixtures.dart';

Future<void> _pump(WidgetTester tester, CommunityAuthor author) =>
    tester.pumpWidget(
      withSession(
        MaterialApp(
          home: Center(child: CommunityAuthorAvatar(author: author)),
        ),
      ),
    );

QeranMonogram _monogram(WidgetTester tester) =>
    tester.widget<QeranMonogram>(find.byType(QeranMonogram));

void main() {
  testWidgets('a matchmaker with a photo: her avatar, with the token, inside '
      'the gold ring (A19)', (tester) async {
    await _pump(tester, nouraWithPhoto);

    final photo = tester.widget<CachedNetworkImage>(
      find.byType(CachedNetworkImage),
    );
    expect(
      photo.imageUrl,
      EndPoints.absoluteUrl('/api/community/avatars/mm-2'),
    );
    expect(photo.httpHeaders, fakeSessionBearer);
    // The brand monogram underneath: its ring frames the photo, and it shows
    // while the photo loads or if it fails.
    expect(_monogram(tester).tone, QeranMonogramTone.brand);
    expect(
      tester.getSize(find.byType(CommunityAuthorAvatar)),
      const Size(44, 44),
    );
  });

  testWidgets('a matchmaker without a photo: the brand monogram', (
    tester,
  ) async {
    await _pump(tester, huda);

    expect(_monogram(tester).tone, QeranMonogramTone.brand);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });

  testWidgets('a member: the plain monogram, never a photo (D10)', (
    tester,
  ) async {
    await _pump(
      tester,
      const CommunityAuthor(
        id: 'u-1',
        displayName: 'سارة',
        isMatchmaker: false,
        profileImageUrl: '/api/community/avatars/u-1',
      ),
    );

    expect(_monogram(tester).tone, QeranMonogramTone.plain);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });
}
