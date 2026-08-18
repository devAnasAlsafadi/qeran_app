import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/presentation/widgets/like_blurred_image.dart';
import 'package:qeran/features/profile/domain/entities/profile_entry_source.dart';
import 'package:qeran/features/profile/domain/entities/profile_image.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_header_gallery.dart';

/// Clear photos live on exactly one surface — the compatibility tab's
/// one-time viewing window. The profile screen must never become a second
/// one, so a peer's photos stay blurred whatever the exchange status says.
void main() {
  const clearPeerPhoto = OtherProfileImage(
    id: 'p1',
    url: 'https://cdn.test/p1.jpg',
    isProfile: true,
    // The server says this member may see it clear — an approved exchange.
    isBlurred: false,
    blurredUrl: 'https://cdn.test/p1-blurred.jpg',
  );

  const ownPhoto = OwnerImage(
    id: 'o1',
    url: 'https://cdn.test/o1.jpg',
    isProfile: true,
  );

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(home: Scaffold(body: SizedBox(height: 400, child: child))),
  );

  LikeBlurredImage firstImage(WidgetTester tester) =>
      tester.widget<LikeBlurredImage>(find.byType(LikeBlurredImage).first);

  testWidgets('a peer photo stays blurred even when the server says clear', (
    tester,
  ) async {
    await pump(
      tester,
      const ProfileHeaderGallery(images: [clearPeerPhoto], forceBlur: true),
    );

    expect(firstImage(tester).blur, isTrue);
  });

  testWidgets('the blur uses the server rendition when there is one', (
    tester,
  ) async {
    await pump(
      tester,
      const ProfileHeaderGallery(images: [clearPeerPhoto], forceBlur: true),
    );

    expect(firstImage(tester).blurredUrl, 'https://cdn.test/p1-blurred.jpg');
  });

  testWidgets('a blurred peer photo is inert — no tap target', (tester) async {
    await pump(
      tester,
      const ProfileHeaderGallery(images: [clearPeerPhoto], forceBlur: true),
    );

    final tap = tester.widget<GestureDetector>(
      find.byKey(const ValueKey<String>('profile-gallery-image-p1')),
    );
    expect(
      tap.onTap,
      isNull,
      reason: 'zooming a redaction shows nothing, and this surface cannot '
          'un-redact it',
    );
  });

  testWidgets('own photos are untouched — clear and still tappable', (
    tester,
  ) async {
    // The same gallery renders the member's own profile in self-mode.
    await pump(tester, const ProfileHeaderGallery(images: [ownPhoto]));

    expect(firstImage(tester).blur, isFalse);
    final tap = tester.widget<GestureDetector>(
      find.byKey(const ValueKey<String>('profile-gallery-image-o1')),
    );
    expect(tap.onTap, isNotNull);
  });

  test('only peer entries force the blur', () {
    for (final entry in [
      ProfileEntrySource.discovery,
      ProfileEntrySource.chat,
      ProfileEntrySource.likes,
      ProfileEntrySource.matches,
    ]) {
      expect(isPeerProfileEntry(entry), isTrue, reason: '$entry');
    }
    for (final entry in [
      ProfileEntrySource.mine,
      ProfileEntrySource.settings,
    ]) {
      expect(isPeerProfileEntry(entry), isFalse, reason: '$entry');
    }
  });
}
