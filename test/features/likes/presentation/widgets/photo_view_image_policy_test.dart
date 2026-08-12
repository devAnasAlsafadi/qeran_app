import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/presentation/blocs/photo_view_state.dart';
import 'package:qeran/features/likes/presentation/widgets/like_blurred_image.dart';
import 'package:qeran/features/likes/presentation/widgets/photo_view_access_host.dart';

Widget _surface(PhotoViewState state) {
  return MaterialApp(
    home: Scaffold(
      body: PhotoViewScope(
        state: state,
        onReveal: () {},
        onRetry: () {},
        onImageForbidden: () {},
        child: const LikeBlurredImage(
          url: 'https://example.invalid/protected.jpg',
          blur: false,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('available state fetches no image bytes', (tester) async {
    await tester.pumpWidget(
      _surface(const PhotoViewState(phase: PhotoViewPhase.available)),
    );

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  testWidgets('viewing uses NetworkImage, not the disk cache widget', (
    tester,
  ) async {
    await tester.pumpWidget(
      _surface(
        const PhotoViewState(
          phase: PhotoViewPhase.viewing,
          secondsRemaining: 60,
        ),
      ),
    );

    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('no exchange keeps the ordinary cached image pipeline', (
    tester,
  ) async {
    await tester.pumpWidget(
      _surface(const PhotoViewState(phase: PhotoViewPhase.unavailable)),
    );

    expect(find.byType(CachedNetworkImage), findsOneWidget);
  });
}
