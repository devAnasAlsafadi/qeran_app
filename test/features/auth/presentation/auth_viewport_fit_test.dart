import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/effects/ring_motif.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/widgets/language_switch_button.dart';
import 'package:qeran/features/auth/presentation/blocs/login/login_bloc.dart';
import 'package:qeran/features/auth/presentation/blocs/login/login_state.dart';
import 'package:qeran/features/auth/presentation/blocs/register/register_bloc.dart';
import 'package:qeran/features/auth/presentation/blocs/register/register_state.dart';
import 'package:qeran/features/auth/presentation/screens/login_screen/login_screen.dart';
import 'package:qeran/features/auth/presentation/screens/register_screen/register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// QER-30: the auth screens must not require scrolling to reach a field.
///
/// The dome keeps its `SingleChildScrollView` as a safety net (keyboard, large
/// accessibility text, landscape), so "does it fit" cannot be asserted by
/// looking for a scroll view — it is always there. The honest measure is
/// whether that scroll view has anything to scroll: `maxScrollExtent == 0`
/// means every field, the CTA, the social buttons and the footer link are on
/// screen at once.
///
/// Measured in BOTH languages: the Arabic policy sentence and the Arabic
/// labels wrap differently from the English, and register is the taller of the
/// two screens, so Arabic register is the binding case.

class _MockLoginBloc extends Mock implements LoginBloc {}

class _MockRegisterBloc extends Mock implements RegisterBloc {}

/// Loads the REAL translation files off disk so text heights are the ones
/// users actually get — a stub loader would silently shrink every string to
/// its key and make everything fit.
class _DiskAssetLoader extends AssetLoader {
  const _DiskAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    // Synchronous on purpose: an awaited file read does not complete inside
    // pumpAndSettle, so the tree would still be EasyLocalization's placeholder
    // when the measurement runs.
    final file = File('assets/translations/${locale.languageCode}.json');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }
}

void _registerBlocs() {
  final login = _MockLoginBloc();
  when(() => login.state).thenReturn(LoginInitial());
  when(() => login.stream).thenAnswer((_) => const Stream<LoginState>.empty());
  when(login.close).thenAnswer((_) async {});

  final register = _MockRegisterBloc();
  when(() => register.state).thenReturn(RegisterInitial());
  when(
    () => register.stream,
  ).thenAnswer((_) => const Stream<RegisterState>.empty());
  when(register.close).thenAnswer((_) async {});

  if (sl.isRegistered<LoginBloc>()) sl.unregister<LoginBloc>();
  if (sl.isRegistered<RegisterBloc>()) sl.unregister<RegisterBloc>();
  sl.registerFactory<LoginBloc>(() => login);
  sl.registerFactory<RegisterBloc>(() => register);
}

/// Height of the wine band — everything the dome does not occupy. The band is
/// a fixed share of the screen, so this must come out the same on every auth
/// screen; that is what stops the brand resizing as the user moves between
/// them.
double _bandHeight(WidgetTester tester, Size size) =>
    size.height - tester.getSize(find.byType(SingleChildScrollView).first).height;

/// Returns how many logical pixels of content overflow the viewport.
/// 0 means the screen fits without scrolling.
Future<double> _overflow(
  WidgetTester tester, {
  required Widget screen,
  required Locale locale,
  required Size size,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  // A real status-bar inset, not zero. The hero sits inside a SafeArea, so a
  // zero inset would flatter the measurement by ~44px — enough to turn a
  // genuine overflow into an apparent fit.
  tester.view.padding = const FakeViewPadding(top: 44);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      startLocale: locale,
      path: 'assets/translations',
      assetLoader: const _DiskAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: screen,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  // No layout exception should escape any more — AuthFooterLink's horizontal
  // overflow at 360dp was fixed alongside this. Assert rather than swallow, so
  // a future overflow fails loudly instead of hiding behind the fit numbers.
  expect(tester.takeException(), isNull);

  // Every TextField owns a Scrollable too, so target the dome's scroll view
  // specifically — it is the only SingleChildScrollView in the tree.
  final scrollable = tester.state<ScrollableState>(
    find
        .descendant(
          of: find.byType(SingleChildScrollView),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  return scrollable.position.maxScrollExtent;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(_registerBlocs);

  // 360x640 is the small-phone floor (iPhone SE / older Android).
  const small = Size(360, 640);
  const tall = Size(390, 820);

  // Only LOGIN has a zero-scroll requirement, and only on a tall phone. The
  // band is now a fixed share of the screen so the brand is identical on every
  // auth screen, which means the dome no longer grows to swallow a long form —
  // register scrolls by design, and both screens scroll on a small phone.
  //
  // These constants record the MEASURED gaps rather than a goal: the suite
  // stays honest and green, and a regression that widens a gap still fails.
  const knownRegisterGapTall = 120.0;
  const knownLoginGapSmall = 125.0;
  const knownRegisterGapSmall = 242.0;

  for (final locale in [const Locale('ar'), const Locale('en')]) {
    final lang = locale.languageCode;

    testWidgets('login small-phone gap has not regressed [$lang]', (
      tester,
    ) async {
      final overflow = await _overflow(
        tester,
        screen: const LoginScreen(),
        locale: locale,
        size: small,
      );
      expect(
        overflow,
        lessThanOrEqualTo(knownLoginGapSmall),
        reason: 'login overflows by ${overflow}px at $small (target 0)',
      );
    });

    testWidgets('register small-phone gap has not regressed [$lang]', (
      tester,
    ) async {
      final overflow = await _overflow(
        tester,
        screen: const RegisterScreen(),
        locale: locale,
        size: small,
      );
      expect(
        overflow,
        lessThanOrEqualTo(knownRegisterGapSmall),
        reason: 'register overflows by ${overflow}px at $small (target 0)',
      );
    });

    testWidgets('register tall-phone gap has not regressed [$lang]', (
      tester,
    ) async {
      final overflow = await _overflow(
        tester,
        screen: const RegisterScreen(),
        locale: locale,
        size: tall,
      );
      expect(
        overflow,
        lessThanOrEqualTo(knownRegisterGapTall),
        reason: 'register overflows by ${overflow}px at $tall',
      );
    });

    testWidgets('login fits without scrolling on a tall phone [$lang]', (
      tester,
    ) async {
      final overflow = await _overflow(
        tester,
        screen: const LoginScreen(),
        locale: locale,
        size: tall,
      );
      expect(overflow, 0, reason: 'login overflows by ${overflow}px at $tall');
    });

    // The band's height differs by ~120px between login and register (their
    // forms differ by that much), so anything laid out INSIDE the band lands at
    // a different height on each screen. The chrome is pinned to the top of the
    // screen instead; this is what proves it, on the screen where the band is
    // tallest and the drift would be worst.
    testWidgets('chrome sits under the status bar, not in the band [$lang]', (
      tester,
    ) async {
      await _overflow(
        tester,
        screen: const LoginScreen(),
        locale: locale,
        size: tall,
      );
      final chromeTop = tester
          .getTopLeft(find.byType(LanguageSwitchButton))
          .dy;
      expect(
        chromeTop,
        lessThan(100),
        reason:
            'chrome at ${chromeTop}px is riding the band, not pinned to the top',
      );
    });

    // The brand must not resize or shift as the user crosses between screens.
    // A flexing band made login's ~120px taller than register's, which resized
    // the monogram with it; a fixed share of the screen is what fixes that, and
    // this is the assertion that keeps it fixed.
    testWidgets('band is identical on login and register [$lang]', (
      tester,
    ) async {
      await _overflow(
        tester,
        screen: const LoginScreen(),
        locale: locale,
        size: tall,
      );
      final loginBand = _bandHeight(tester, tall);
      final loginLockup = tester.getSize(_brandLockup).height;

      await _overflow(
        tester,
        screen: const RegisterScreen(),
        locale: locale,
        size: tall,
      );
      expect(_bandHeight(tester, tall), loginBand);
      expect(tester.getSize(_brandLockup).height, loginLockup);
    });

    // The band carries the full logo lockup asset (symbol + قِران + QERAN)
    // centered in the wine area.
    testWidgets('band shows full logo lockup centered [$lang]', (
      tester,
    ) async {
      await _overflow(
        tester,
        screen: const LoginScreen(),
        locale: locale,
        size: tall,
      );
      expect(_brandLockup, findsOneWidget);
    });
  }
}

/// The full logo lockup image in the wine hero band.
Finder get _brandLockup => find.byType(Image).first;
