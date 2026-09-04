import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/match_image.dart';
import 'package:qeran/features/likes/presentation/widgets/like_blurred_image.dart';
import 'package:qeran/features/likes/presentation/widgets/match_gallery_sheet.dart';
import 'package:qeran/features/likes/presentation/widgets/match_photo_pager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opening a photo expands the SHEET rather than moving the photo out of it.
/// That is the whole design: the pager stays inside `PhotoViewScope`, so the
/// only thing allowed to change is the host's height.
///
/// The height is the load-bearing half and the mutants confirm it: dropping
/// either `_resize` call, or changing either size, fails these.
///
/// The survival half is a GUARD, and honestly labelled as one. Measured,
/// `DraggableScrollableSheet` hands its builder's output on as a cached child:
/// across a whole open-and-expand the builder runs twice (the sheet, then the
/// open) and the pager's state is constructed once, so the resize cannot drop
/// the open page or its zoom — no mutation of this file makes those
/// assertions fail. They are here to catch the day that stops being true: a
/// host that rebuilds per tick, or a key added above the pager, would replace
/// the element and the member would watch their one opening snap back to page
/// one at zoom 1 mid-animation.
class _StubLoader extends AssetLoader {
  const _StubLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

const _screen = Size(400, 800);

List<MatchImage> _images() => [
  for (var i = 0; i < 3; i++)
    MatchImage(
      id: 'i$i',
      url: 'https://cdn.test/$i.jpg',
      isProfile: i == 0,
      isBlurred: false,
    ),
];

/// The grid's top edge sits a FIXED distance below the sheet's own top, so its
/// movement is the sheet's movement — measured without depending on the exact
/// header height or the safe-area inset.
double _gridTop(WidgetTester tester) =>
    tester.getTopLeft(find.byType(GridView)).dy;

InteractiveViewer _viewerFor(WidgetTester tester, String id) => tester.widget(
  find.descendant(
    of: find.byKey(ValueKey<String>('match-photo-page-$id')),
    matching: find.byType(InteractiveViewer),
  ),
);

Future<void> _openSheet(WidgetTester tester) async {
  tester.view.physicalSize = _screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      path: 'unused',
      assetLoader: const _StubLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Builder(
            builder: (inner) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () =>
                      showMatchGallerySheet(inner, images: _images()),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('opening a photo raises the sheet, closing it lowers it again', (
    tester,
  ) async {
    await _openSheet(tester);
    final resting = _gridTop(tester);

    await tester.tap(find.byType(LikeBlurredImage).at(0));
    await tester.pumpAndSettle();
    final expanded = _gridTop(tester);

    // 0.7 -> 0.95 of an 800pt screen. Asserting "it moved up" would pass on a
    // one-pixel nudge; asserting the distance pins the two sizes themselves.
    expect(
      resting - expanded,
      closeTo(0.25 * _screen.height, 8),
      reason: 'the sheet must travel the full 0.7 -> 0.95',
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(
      _gridTop(tester),
      closeTo(resting, 1),
      reason: 'closing must give the sheet back, not leave it stuck open',
    );
  });

  testWidgets('the open photo survives the expand', (tester) async {
    await _openSheet(tester);
    final resting = _gridTop(tester);

    // The SECOND tile: a pager that were rebuilt from scratch would come back
    // on page 1, which opening the first tile could never reveal.
    await tester.tap(find.byType(LikeBlurredImage).at(1));
    await tester.pump();

    final pager = tester.state(find.byType(MatchPhotoPager));
    expect(find.text('2 / 3'), findsOneWidget);
    _viewerFor(tester, 'i1').transformationController!.value =
        Matrix4.diagonal3Values(2, 2, 1);
    await tester.pump(const Duration(milliseconds: 16));

    await tester.pumpAndSettle();

    expect(
      resting - _gridTop(tester),
      closeTo(0.25 * _screen.height, 8),
      reason: 'the resize never ran — nothing below was actually tested',
    );
    expect(
      tester.state(find.byType(MatchPhotoPager)),
      same(pager),
      reason: 'the pager was replaced, not updated — its page and zoom are '
          'gone even though the screenshot looks right',
    );
    expect(find.text('2 / 3'), findsOneWidget, reason: 'page index survived');
    expect(
      _viewerFor(tester, 'i1').transformationController!.value
          .getMaxScaleOnAxis(),
      2,
      reason: 'the zoom lives in the PAGE state, which the resize must not '
          'take down either',
    );
  });
}
