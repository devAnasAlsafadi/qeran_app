import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/match_image.dart';
import 'package:qeran/features/likes/presentation/blocs/photo_view_state.dart';
import 'package:qeran/features/likes/presentation/widgets/match_photo_pager.dart';
import 'package:qeran/features/likes/presentation/widgets/photo_view_access_host.dart';

/// Shared fixtures for the pager's access and paging suites.
///
/// The pager replaced a surface that was safe for a structural reason: it
/// showed ONE photo, chosen by a tap the grid could refuse. A swipe reaches
/// photos no tap gated, so `PhotoViewScope` is now the only thing standing
/// between a locked photo and its original bytes — and [requestedUrls] is how
/// these suites check the bytes rather than the wiring.
const String original0 = 'https://cdn.test/0.jpg';
const String original1 = 'https://cdn.test/1.jpg';
const String original2 = 'https://cdn.test/2.jpg';
const String blurred1 = 'https://cdn.test/1-blurred.jpg';

const Set<String> originals = {original0, original1, original2};

/// Three photos. [secondIsBlurred] makes the middle one server-blurred, which
/// is the mix a swipe crosses and a tap gate never could.
List<MatchImage> images({bool secondIsBlurred = false}) => [
  const MatchImage(
    id: 'i0',
    url: original0,
    isProfile: true,
    isBlurred: false,
  ),
  if (secondIsBlurred)
    const MatchImage(
      id: 'i1',
      url: original1,
      isProfile: false,
      isBlurred: true,
      blurredUrl: blurred1,
    )
  else
    const MatchImage(
      id: 'i1',
      url: original1,
      isProfile: false,
      isBlurred: false,
    ),
  const MatchImage(
    id: 'i2',
    url: original2,
    isProfile: false,
    isBlurred: false,
  ),
];

/// Every URL an image provider in the tree is actually pointed at — the
/// `CachedNetworkImage` path and the memory-only `Image(NetworkImage(...))`
/// path alike, so neither can be swapped in unnoticed.
Set<String> requestedUrls(WidgetTester tester) {
  final urls = <String>{};
  for (final widget in tester.allWidgets) {
    if (widget is CachedNetworkImage) urls.add(widget.imageUrl);
    if (widget is Image) {
      final provider = widget.image;
      if (provider is NetworkImage) urls.add(provider.url);
    }
  }
  return urls;
}

Widget host({
  required PhotoViewState state,
  required List<MatchImage> list,
  int initialIndex = 0,
  TextDirection direction = TextDirection.rtl,
  VoidCallback? onClose,
}) {
  return MaterialApp(
    home: Directionality(
      textDirection: direction,
      child: Scaffold(
        body: PhotoViewScope(
          state: state,
          onReveal: () {},
          onRetry: () {},
          onImageForbidden: () {},
          child: MatchPhotoPager(
            images: list,
            initialIndex: initialIndex,
            onClose: onClose ?? () {},
          ),
        ),
      ),
    ),
  );
}

/// Forward is start→end, which `PageView` mirrors on its own.
Future<void> swipeForward(WidgetTester tester, TextDirection direction) async {
  await tester.drag(
    find.byType(PageView),
    Offset(direction == TextDirection.rtl ? 600 : -600, 0),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
}
