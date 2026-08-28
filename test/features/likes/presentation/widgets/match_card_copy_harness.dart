import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/theme/qeran_theme.dart';
import 'package:qeran/core/design_system/tokens/qeran_spacing.dart';
import 'package:qeran/features/likes/domain/entities/match_card.dart';
import 'package:qeran/features/likes/domain/entities/match_case_stage.dart';
import 'package:qeran/features/likes/domain/entities/match_case_status.dart';
import 'package:qeran/features/likes/domain/entities/match_image.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/pending_formal_step.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_direction.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_pending.dart';
import 'package:qeran/features/likes/domain/entities/photo_exchange_status.dart';
import 'package:qeran/features/likes/presentation/widgets/match_card.dart';

/// Shared rig for measuring whether SHIPPED match-card copy fits its slot.
///
/// Everything here runs against the REAL translation files rather than a stub
/// loader. A stub renders each key as its own name, and those names are much
/// longer than the copy they stand for — long enough to overflow neighbouring
/// widgets and drown the assertions in unrelated layout errors. Reading the
/// shipped strings also means these tests fail if the wording regresses, which
/// is the point of them.
///
/// [loadShippedFonts] and [QeranTheme] are both required, not optional
/// polish. Without them a width guard measures nothing useful: the default
/// test font draws every glyph as a full em square, which overstates Arabic by
/// roughly double and would fail copy that fits comfortably on a device.

class DiskLoader extends AssetLoader {
  const DiskLoader();

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
Future<void> loadShippedFonts() async {
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
String shipped(Locale locale, String key) {
  final file = File('assets/translations/${locale.languageCode}.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (json['likes'] as Map<String, dynamic>)[key] as String;
}

/// True when the text at [finder] had to ellipsise to fit its slot.
bool isTruncated(WidgetTester tester, Finder finder) =>
    tester.renderObject<RenderParagraph>(finder).didExceedMaxLines;

MatchCard copyCard(
  MatchStage stage, {
  MatchCaseStage caseStage = MatchCaseStage.unknown,
  MatchCaseStatus caseStatus = MatchCaseStatus.active,
  String name = 'User',
  PhotoExchangePending? pendingPhotoExchange,
  PendingFormalStep? pendingFormalStep,
}) => MatchCard(
  likeRequestId: 1,
  otherUserId: 'u1',
  otherUserName: name,
  images: [
    const MatchImage(
      id: '7',
      url: 'https://example.invalid/p.jpg',
      isProfile: true,
      isBlurred: true,
    ),
  ],
  stage: stage,
  pendingPhotoExchange: pendingPhotoExchange,
  formalRequest: null,
  conversationId: null,
  caseStage: caseStage,
  caseStatus: caseStatus,
  pendingFormalStep: pendingFormalStep,
);

/// The widest countdown the chip can ever show, in seconds.
///
/// NOT the largest number — the formatter buckets, and `23h 59m` picks the
/// two-unit hours/minutes template («٢٣ ساعة و ٥٩ دقيقة») which is longer in
/// Arabic than any days/hours pairing. A guard fed "3 days" measures a chip
/// roughly 20dp narrower than the one that actually ships.
const int kWidestCountdownSeconds = 23 * 3600 + 59 * 60;

/// A request I SENT that is still counting down: chip on the header, no
/// responder buttons, and — from sub-step 5d — the cancel X beside it. The
/// state that puts the most pressure on the header row.
PhotoExchangePending livePhotoRequestFromMe({
  int remainingSeconds = kWidestCountdownSeconds,
}) => PhotoExchangePending(
  id: 5,
  likeRequestId: 1,
  initiatorId: 'me',
  responderId: 'them',
  status: PhotoExchangeStatus.pending,
  statusCode: 0,
  remainingSeconds: remainingSeconds,
  createdAt: DateTime.utc(2026),
  expiresAt: DateTime.utc(2099),
  direction: PhotoExchangeDirection.sent,
  requestedByMe: true,
  canAccept: false,
  canReject: false,
);

/// A long but realistic full name in each language, for width guards.
///
/// Arabic is the binding case: it renders wider per character in the shipped
/// Kufi face, and the Matches list is Arabic-first.
const Map<String, String> kLongNames = {
  'ar': 'عبد الرحمن بن عبد العزيز',
  'en': 'Abdulrahman Al-Mutairi',
};

/// Stage 0 with an incoming request I may answer — the only state that renders
/// the reject/accept pair.
MatchCard cardAwaitingMyResponse() {
  final card = copyCard(MatchStage.waitingForPhotoExchange);
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

/// Pumps one card at [size], inset exactly as the Matches list insets it.
///
/// [size] is a real SCREEN width, not a card width. `_MatchesList` pads every
/// row by `QeranSpacing.s20` on both sides, so a card pumped bare measures
/// 40dp wider than the one that ships — enough to hide a clipped name at
/// 320dp entirely. Everything here is measured through [kListInset] for that
/// reason.
const double kListInset = QeranSpacing.s20;

Future<void> pumpMatchCard(
  WidgetTester tester, {
  required MatchCard card,
  Locale locale = const Locale('ar'),
  Size size = const Size(360, 900),
  VoidCallback? onCancelCase,
  bool isCancelling = false,
  VoidCallback? onOpenProfile,
  bool settle = true,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      startLocale: locale,
      path: 'unused',
      assetLoader: const DiskLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          theme: QeranTheme.light(locale),
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: kListInset),
              child: MatchCardWidget(
                card: card,
                onFormalStep: () {},
                onCancelCase: onCancelCase,
                isCancelling: isCancelling,
                onOpenProfile: onOpenProfile,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
    return;
  }
  // A card holding a spinner never settles — `CircularProgressIndicator`
  // animates forever, and `pumpAndSettle` waits for it. Pumping a fixed
  // number of frames is enough to get EasyLocalization past its placeholder,
  // which is the only thing the settle was ever needed for.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// The string a user in [locale] sees for `<section>.<key>` — the general
/// form of [shipped], which is pinned to the `likes` section.
String shippedSection(Locale locale, String section, String key) {
  final file = File('assets/translations/${locale.languageCode}.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return (json[section] as Map<String, dynamic>)[key] as String;
}
