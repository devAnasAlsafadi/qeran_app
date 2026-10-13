import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/theme/qeran_theme.dart';
import 'package:qeran/core/design_system/tokens/qeran_typography.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/design_system/widgets/qeran_monogram.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:qeran/features/matchmaker/account/presentation/widgets/matchmaker_account_body.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_state.dart';
import 'package:qeran/features/profile/presentation/screens/profile_screen.dart';
import 'package:qeran/features/profile/presentation/widgets/profile_upgrade_banner.dart';
import 'package:qeran/features/settings/presentation/widgets/settings_profile_hero.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';

import '../../../../core/shipped_fonts_rig.dart';
import '../../../../core/shipped_strings_rig.dart';
import '../../../matchmaker/account/matchmaker_me_fixtures.dart';

/// Run 8 (the client): the name card and the upgrade card took over half the
/// screen. Now a compact name card (both apps) and a slim banner — the title,
/// the approved line, a small button beside them. Measured in the shipped
/// fonts on a 360×760 phone.

class _Session extends Fake implements UserSessionCubit {
  @override
  UserSessionState get state => const UserSessionInitial();
  @override
  Stream<UserSessionState> get stream => const Stream.empty();
}

class _Gate extends Fake implements ProfileGateCubit {
  @override
  ProfileGateState get state => const ProfileGateResolved(
    ProfileStatus.visible,
    name: 'Mohammad Ibrahim',
  );
  @override
  Stream<ProfileGateState> get stream => const Stream.empty();
}

/// No subscription, so the banner shows.
class _Subscription extends Fake implements CurrentSubscriptionCubit {
  @override
  CurrentSubscriptionState get state => const CurrentSubscriptionInitial();
  @override
  Stream<CurrentSubscriptionState> get stream => const Stream.empty();
  @override
  Future<void> refresh({bool force = false}) async {}
}

Future<void> _pump(WidgetTester tester, Locale locale, Widget child) async {
  tester.view.physicalSize = const Size(360, 760);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpShippedStrings(
    tester,
    locale,
    builder: (context, nav) =>
        Theme(data: QeranTheme.light(locale), child: nav!),
    child: MultiBlocProvider(
      providers: [
        BlocProvider<UserSessionCubit>.value(value: _Session()),
        BlocProvider<ProfileGateCubit>.value(value: _Gate()),
        BlocProvider<CurrentSubscriptionCubit>.value(value: _Subscription()),
      ],
      child: child,
    ),
  );
}

MatchmakerAccountBody _herAccount() => MatchmakerAccountBody(
  me: meWith(),
  onEditName: () {},
  onChangePassword: () {},
  onLanguage: () {},
  onNotifications: () {},
  onSupport: () {},
  onTerms: () {},
  onAffiliate: () {},
  onDeactivate: () {},
  onDeleteAccount: () {},
  onLogout: () {},
  loadErrorKey: null,
  onRetryLoad: () {},
  bottomReserve: 0,
);

Finder _inBanner(Finder f) =>
    find.descendant(of: find.byType(ProfileUpgradeBanner), matching: f);

void main() {
  setUpAll(() async {
    await initShippedStrings();
    await loadShippedFonts();
  });

  for (final locale in const [Locale('ar'), Locale('en')]) {
    final lang = locale.languageCode;

    testWidgets('the name card and the banner take under a third of the '
        'screen [$lang]', (tester) async {
      await _pump(tester, locale, const ProfileScreen());

      final hero = tester.getRect(find.byType(SettingsProfileHero));
      final banner = tester.getRect(find.byType(ProfileUpgradeBanner));
      expect(banner.bottom - hero.top, lessThan(760 / 3));
    });

    testWidgets('the banner: title and line, a small button beside them '
        '[$lang]', (tester) async {
      await _pump(tester, locale, const ProfileScreen());

      final banner = tester.getRect(find.byType(ProfileUpgradeBanner));
      final title = tester.getRect(
        _inBanner(find.text(shipped(lang, 'profile.upsell_title'))),
      );
      final line = tester.getRect(
        _inBanner(find.text(shipped(lang, 'profile.upsell_teaser_1'))),
      );
      final button = tester.getRect(_inBanner(find.byType(QeranButton)));
      expect(find.text(shipped(lang, 'profile.upsell_cta')), findsOneWidget);
      expect(button.width, lessThan(banner.width / 2));
      expect(button.center.dy, inInclusiveRange(title.top, line.bottom));
      if (lang == 'ar') {
        expect(button.right, lessThanOrEqualTo(line.left));
      } else {
        expect(button.left, greaterThanOrEqualTo(line.right));
      }
    });

    testWidgets('both apps\' name cards: a 48 avatar, the name at title '
        'size [$lang]', (tester) async {
      for (final (screen, name) in [
        (const ProfileScreen() as Widget, 'Mohammad Ibrahim'),
        (_herAccount() as Widget, meWith().name),
      ]) {
        await _pump(tester, locale, screen);
        final hero = find.byType(SettingsProfileHero);
        final avatar = find.descendant(
          of: hero,
          matching: find.byType(QeranMonogram),
        );
        expect(tester.getSize(avatar), const Size.square(48));
        final text = find.descendant(of: hero, matching: find.text(name));
        expect(
          tester.widget<Text>(text).style!.fontSize,
          QeranTypography.title.fontSize,
        );
      }
    });
  }
}
