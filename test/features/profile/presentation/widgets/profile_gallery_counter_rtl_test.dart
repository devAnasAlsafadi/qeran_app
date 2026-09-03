import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/profile/domain/entities/profile_image.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_header_gallery.dart';

/// The photo counter is a ratio, not prose: `1 / 5` means "the first of five"
/// in every language. Left to the ambient direction it does NOT survive
/// Arabic — the bidi algorithm treats the separator between two numbers as
/// RTL (rule N1), reverses the run, and photo 1 of 2 renders as `2 / 1`.
///
/// These tests pin the DISPLAYED order rather than the widget's
/// `textDirection` field, so they still fail if the fix is later reverted by
/// some other route (a wrapping direction, a different string shape).
void main() {
  List<ProfileImage> photos(int count) => <ProfileImage>[
    for (var i = 0; i < count; i++)
      OwnerImage(
        id: 'photo-$i',
        url: 'https://cdn.test/photo-$i.jpg',
        isProfile: i == 0,
      ),
  ];

  Future<void> pump(WidgetTester tester, TextDirection direction) =>
      tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: Scaffold(
              body: SizedBox(
                height: 400,
                child: ProfileHeaderGallery(images: photos(5)),
              ),
            ),
          ),
        ),
      );

  /// Left edge of the glyphs for `text[start..end]` as actually laid out.
  double leftEdgeOf(WidgetTester tester, int start, int end) {
    final paragraph = tester.renderObject<RenderParagraph>(find.text('1 / 5'));
    return paragraph
        .getBoxesForSelection(
          TextSelection(baseOffset: start, extentOffset: end),
        )
        .first
        .toRect()
        .left;
  }

  // '1 / 5' → index 0 is the position, index 4 is the total.
  double positionLeft(WidgetTester tester) => leftEdgeOf(tester, 0, 1);
  double totalLeft(WidgetTester tester) => leftEdgeOf(tester, 4, 5);

  testWidgets('reads 1 / 5 in Arabic, not 5 / 1', (tester) async {
    await pump(tester, TextDirection.rtl);

    expect(
      positionLeft(tester),
      lessThan(totalLeft(tester)),
      reason: 'the current photo must be drawn to the LEFT of the total — '
          'reversed, "1 / 5" reads as "5 / 1" and the member is told they '
          'are on photo 5 of 1',
    );
  });

  testWidgets('reads 1 / 5 in English too', (tester) async {
    await pump(tester, TextDirection.ltr);

    expect(
      positionLeft(tester),
      lessThan(totalLeft(tester)),
      reason: 'guards the fix against being pinned to rtl only',
    );
  });
}
