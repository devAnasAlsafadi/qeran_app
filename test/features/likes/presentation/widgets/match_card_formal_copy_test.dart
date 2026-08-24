import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/theme/qeran_theme.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_image.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_direction.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_pending.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_status.dart';
import 'package:qeran/features/likes/presentation/widgets/match_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The formal-step CTA carries a helper line explaining what pressing it sets
/// in motion, and both it and the photo-exchange reject button took longer
/// wording. `QeranButton` renders its label with `maxLines: 1` and an ellipsis,
/// so a label that outgrows its slot does not wrap — it silently truncates.
///
/// Everything here runs against the REAL translation files rather than a stub
/// loader. A stub renders each key as its own name, and those names are much
/// longer than the copy they stand for — long enough to overflow neighbouring
/// widgets and drown the assertions in unrelated layout errors. Reading the
/// shipped strings also means these tests fail if the wording regresses, which
/// is the point of them.
///
/// The width guard loads the SHIPPED fonts and the real theme. Without both it
/// measures nothing useful: the default test font draws every glyph as a full
/// em square, which overstates Arabic by roughly double and would fail copy
/// that fits comfortably on a device.

class _DiskLoader extends AssetLoader {
  const _DiskLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    // Synchronous on purpose: an awaited read does not complete inside
    // pumpAndSettle, so the tree would still be EasyLocalization's
    // placeholder when the assertions run.
    final file = File('assets/translations/${locale.languageCode}.json');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}

/// Registers the two shipped families so text measures at production widths.
Future<void> _loadFonts() async {
  const families = {
    'NotoKufiArabic': 'assets/fonts/NotoKufiArabic-Bold.ttf',
    'Montserrat': 'assets/fonts/Montserrat-Bold.ttf',
  };
  for (final entry in families.entries) {
    final loader = FontLoader(entry.key)
      ..addFont(
        File(entry.value).readAsBytes().then(
          (bytes) => ByteData.view(Uint8List.fromList(bytes).buffer),
        ),
      );
    await loader.load();
  }
}

/// The string a user in [locale] actually sees for `likes.<key>`.
String _shipped(Locale locale, String key) {
  final file = File('assets/translations/${locale.languageCode}.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (json['likes'] as Map<String, dynamic>)[key] as String;
}

MatchCard _card(MatchStage stage) => MatchCard(
  likeRequestId: 1,
  otherUserId: 'u1',
  otherUserName: 'User',
  images: [
    const MatchImage(
      id: '7',
      url: 'https://example.invalid/p.jpg',
      isProfile: true,
      isBlurred: true,
    ),
  ],
  stage: stage,
  pendingPhotoExchange: null,
  formalRequest: null,
  conversationId: null,
);

/// Stage 0 with an incoming request I may answer — the only state that renders
/// the reject/accept pair.
MatchCard _cardAwaitingMyResponse() {
  final card = _card(MatchStage.waitingForPhotoExchange);
  return MatchCard(
    likeRequestId: card.likeRequestId,
    otherUserId: card.otherUserId,
    otherUserName: card.otherUserName,
    images: card.images,
    stage: card.stage,
    pendingPhotoExchange: PhotoExchangePending(
      id: 5,
      likeRequestId: card.likeRequestId,
      initiatorId: 'them',
      responderId: 'me',
      status: PhotoExchangeStatus.pending,
      statusCode: 0,
      remainingSeconds: 3600,
      createdAt: DateTime.utc(2026),
      expiresAt: DateTime.utc(2099),
      direction: PhotoExchangeDirection.received,
      requestedByMe: false,
      canAccept: true,
      canReject: true,
    ),
    formalRequest: null,
    conversationId: null,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required MatchCard card,
  Locale locale = const Locale('ar'),
  Size size = const Size(360, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      startLocale: locale,
      path: 'unused',
      assetLoader: const _DiskLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          theme: QeranTheme.light(locale),
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MatchCardWidget(card: card, onFormalStep: () {}),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// True when the text at [finder] had to ellipsise to fit its slot.
bool _isTruncated(WidgetTester tester, Finder finder) =>
    tester.renderObject<RenderParagraph>(finder).didExceedMaxLines;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await _loadFonts();
    await EasyLocalization.ensureInitialized();
  });

  group('formal-step helper', () {
    const helperKey = 'matches_formal_step_helper';

    testWidgets('reaches stage 1', (tester) async {
      await _pump(tester, card: _card(MatchStage.photosExchanged));

      expect(
        find.text(_shipped(const Locale('ar'), helperKey)),
        findsOneWidget,
      );
    });

    testWidgets('reaches stage 2', (tester) async {
      await _pump(tester, card: _card(MatchStage.matchmakerEngaged));

      expect(
        find.text(_shipped(const Locale('ar'), helperKey)),
        findsOneWidget,
      );
    });

    testWidgets('stays off stage 0, which has no formal CTA', (tester) async {
      await _pump(tester, card: _card(MatchStage.waitingForPhotoExchange));

      expect(find.text(_shipped(const Locale('ar'), helperKey)), findsNothing);
    });
  });

  group('shipped copy fits its button at 320dp', () {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      final lang = locale.languageCode;

      testWidgets('formal-step CTA is not ellipsised [$lang]', (tester) async {
        await _pump(
          tester,
          card: _card(MatchStage.matchmakerEngaged),
          locale: locale,
          size: const Size(320, 900),
        );

        final label = find.text(_shipped(locale, 'matches_formal_step_cta'));
        expect(label, findsOneWidget, reason: 'CTA label not rendered');
        expect(
          _isTruncated(tester, label),
          isFalse,
          reason: 'formal-step CTA truncates at 320dp in $lang',
        );
      });

      // The tightest slot in the feature: reject and accept split one card
      // width between them, so each label gets well under half of what the
      // formal CTA has to work with.
      testWidgets('photo-exchange reject is not ellipsised [$lang]', (
        tester,
      ) async {
        await _pump(
          tester,
          card: _cardAwaitingMyResponse(),
          locale: locale,
          size: const Size(320, 900),
        );

        final label = find.text(
          _shipped(locale, 'matches_photo_exchange_action_reject'),
        );
        expect(label, findsOneWidget, reason: 'reject label not rendered');
        expect(
          _isTruncated(tester, label),
          isFalse,
          reason: 'reject label truncates at 320dp in $lang',
        );
      });
    }
  });
}
