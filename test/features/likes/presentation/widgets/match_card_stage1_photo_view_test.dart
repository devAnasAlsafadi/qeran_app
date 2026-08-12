import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_image.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/presentation/widgets/match_card_stage1.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _EmptyLoader extends AssetLoader {
  const _EmptyLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

MatchCard _card({required bool isBlurred}) => MatchCard(
  likeRequestId: 1,
  otherUserId: 'u1',
  otherUserName: 'User',
  images: [
    MatchImage(
          id: '7',
      url: 'https://example.invalid/protected.jpg',
      isProfile: true,
      isBlurred: isBlurred,
    ),
  ],
  stage: MatchStage.photosExchanged,
  pendingPhotoExchange: null,
  formalRequest: null,
  conversationId: null,
);

Future<void> _pump(WidgetTester tester, MatchCard card) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      path: 'unused',
      assetLoader: const _EmptyLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: MatchCardStage1(
              card: card,
              onOpenGallery: () {},
              onFormalStep: () {},
              isFormalStepSending: false,
              isFormalStepSent: false,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('available exchange offers reveal without fetching clear bytes', (
    tester,
  ) async {
    await _pump(tester, _card(isBlurred: false));

    expect(find.text(LocaleKeys.likes_matches_photo_view_show), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
    expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
  });

  testWidgets('consumed exchange removes the reveal action', (tester) async {
    await _pump(tester, _card(isBlurred: true));

    expect(find.text(LocaleKeys.likes_matches_photo_view_show), findsNothing);
    expect(
      find.text(LocaleKeys.likes_matches_photo_view_consumed),
      findsOneWidget,
    );
  });
}
