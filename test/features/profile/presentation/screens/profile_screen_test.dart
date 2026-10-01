import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_state.dart';
import 'package:qeran/features/profile/presentation/screens/profile_screen.dart';
import 'package:qeran/features/settings/presentation/widgets/settings_row.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The translation files the app ships, read straight from disk: the asset
/// bundle's own loading never finishes under the test clock.
class _ShippedLoader extends AssetLoader {
  const _ShippedLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      _shipped(locale);
}

Map<String, dynamic> _shipped(Locale locale) =>
    jsonDecode(
          File(
            'assets/translations/${locale.languageCode}.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

class _Session extends Fake implements UserSessionCubit {
  @override
  UserSessionState get state => const UserSessionInitial();
  @override
  Stream<UserSessionState> get stream => const Stream.empty();
}

class _Gate extends Fake implements ProfileGateCubit {
  @override
  ProfileGateState get state => const ProfileGateInitial();
  @override
  Stream<ProfileGateState> get stream => const Stream.empty();
}

/// No subscription yet, so the upsell card shows.
class _Subscription extends Fake implements CurrentSubscriptionCubit {
  @override
  CurrentSubscriptionState get state => const CurrentSubscriptionInitial();
  @override
  Stream<CurrentSubscriptionState> get stream => const Stream.empty();
  @override
  Future<void> refresh({bool force = false}) async {}
}

Future<void> _pump(WidgetTester tester, Locale locale) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: [locale],
      path: 'assets/translations',
      assetLoader: const _ShippedLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: MultiBlocProvider(
            providers: [
              BlocProvider<UserSessionCubit>.value(value: _Session()),
              BlocProvider<ProfileGateCubit>.value(value: _Gate()),
              BlocProvider<CurrentSubscriptionCubit>.value(
                value: _Subscription(),
              ),
            ],
            child: const Scaffold(body: ProfileScreen()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _text(Locale locale, String section, String key) =>
    (_shipped(locale)[section] as Map<String, dynamic>)[key] as String;

/// What the upsell card said before its text moved to the translation files,
/// word for word. Its first teaser is rewritten in the Phase 4 copy pass.
const _upsell = {
  'ar': [
    'ارتقِ لعضوية التميز',
    'افتح كافة ميزات قِران الفريدة وتعرّف على شريكك اليوم',
    'إعجابات وتواصل بلا حدود مع الطرف الآخر',
    'تبادل الصور بأمان وسرية تامة',
    'اكتشف الباقات',
  ],
  'en': [
    'Upgrade to Premium',
    'Unlock premium features and find your match today',
    'Unlimited likes and match connections',
    'Secure and private photo exchange',
    'See Plans',
  ],
};

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final locale in const [Locale('ar'), Locale('en')]) {
    final lang = locale.languageCode;

    // The bell in the top bar is the way to the inbox now.
    testWidgets('no Notifications row [$lang]', (tester) async {
      await _pump(tester, locale);

      expect(
        find.text(_text(locale, 'settings', 'notifications_row')),
        findsNothing,
      );
      expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    });

    // The chat bubble belongs to the matchmaker chat, not to support.
    testWidgets('Help & support wears the help glyph [$lang]', (tester) async {
      await _pump(tester, locale);

      final row = tester.widget<SettingsRow>(
        find.ancestor(
          of: find.text(_text(locale, 'settings', 'support_row')),
          matching: find.byType(SettingsRow),
        ),
      );
      expect(row.icon, Icons.help_outline_rounded);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);
    });

    testWidgets('the upsell card keeps today\'s wording [$lang]', (
      tester,
    ) async {
      await _pump(tester, locale);

      for (final line in _upsell[lang]!) {
        expect(find.text(line), findsOneWidget, reason: line);
      }
    });
  }
}
