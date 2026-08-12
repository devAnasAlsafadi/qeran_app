// easy_localization re-exports intl, whose TextDirection collides with
// dart:ui's — the one Directionality actually takes.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/like_request_card.dart';
import 'package:qeran/features/likes/domain/entities/like_request_status.dart';
import 'package:qeran/features/likes/presentation/widgets/like_card_countdown_chip.dart';
import 'package:qeran/features/likes/presentation/widgets/like_user_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A three-part name next to the live countdown chip was being cut to
/// "Anas Ashraf Al…". The chip legitimately owns the end of the top line, so
/// the name has to wrap under itself rather than abbreviate — a name is the one
/// thing on this row that must arrive intact.
///
/// Asserted through the ROW's height rather than the paragraph's pixels: the
/// widget-test font is not the shipped one, so any absolute text measurement
/// here would be measuring the wrong glyphs. Comparing a long name against a
/// short one on the same surface cancels the font out entirely.

/// Carries the countdown copy for real. Left as raw keys the chip would be
/// absurdly wide, which is the very thing that squeezes the name — the test
/// would then pass for the wrong reason.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {
        'likes': {
          'time_left_days_hours': '{days}ي {hours}س',
          'status_waiting_reply': 'بانتظار الرد',
        },
        'matchmaker': {'users_age_years': '{age} سنة'},
      };
}

const String _longName = 'Anas Ashraf Alsafadi';
const String _shortName = 'anas';

LikeRequestCard _card(String name) => LikeRequestCard(
  likeRequestId: 1,
  profileId: 'p1',
  name: name,
  profileImage: null,
  status: LikeRequestStatus.pending,
  createdAt: null,
  remainingSeconds: 90000,
  actions: const [],
  isLocked: false,
);

LikeRequestCard _cardWithFacts() => const LikeRequestCard(
  likeRequestId: 2,
  profileId: 'p2',
  name: 'User',
  profileImage: null,
  age: 31,
  residence: 'Jordan',
  job: 'Engineer',
  status: LikeRequestStatus.accepted,
  createdAt: null,
  remainingSeconds: null,
  actions: [],
  isLocked: false,
);

Future<void> _pump(WidgetTester tester, String name) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      startLocale: const Locale('ar'),
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: Align(
                alignment: Alignment.topCenter,
                child: LikeUserCard(card: _card(name)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpCard(WidgetTester tester, LikeRequestCard card) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      startLocale: const Locale('ar'),
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: Scaffold(body: LikeUserCard(card: card)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

double _rowHeight(WidgetTester tester) =>
    tester.getSize(find.byType(LikeUserCard)).height;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('the name is allowed to wrap, not just ellipsised', (
    tester,
  ) async {
    await _pump(tester, _longName);

    final name = tester.widget<Text>(find.text(_longName));
    expect(name.maxLines, kLikeCardNameMaxLines);
    expect(name.maxLines, greaterThan(1));
  });

  testWidgets('a long name makes the row taller instead of being cut', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pump(tester, _shortName);
    final short = _rowHeight(tester);

    await _pump(tester, _longName);
    final long = _rowHeight(tester);

    // Truncating to one line would have kept the row exactly as tall.
    expect(long, greaterThan(short));
  });

  testWidgets('the countdown chip keeps its place; the name wraps beside it', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pump(tester, _longName);

    // Direction-agnostic: in RTL the chip sits at the left, in LTR the right.
    // Either way the name wraps inside its own column and never runs under it.
    final name = tester.getRect(find.text(_longName));
    final chip = tester.getRect(find.byType(LikeCountdownChip));
    expect(name.overlaps(chip), isFalse);
  });

  testWidgets('age, residence, and job are displayed below the name', (
    tester,
  ) async {
    await _pumpCard(tester, _cardWithFacts());

    expect(find.textContaining('31'), findsOneWidget);
    expect(find.text('Jordan'), findsOneWidget);
    expect(find.text('Engineer'), findsOneWidget);
  });
}
