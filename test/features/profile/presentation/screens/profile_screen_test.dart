import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_state.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';
import 'package:qeran/features/profile/domain/entities/profile_status.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_state.dart';
import 'package:qeran/features/profile/presentation/screens/profile_screen.dart';
import 'package:qeran/features/settings/presentation/widgets/settings_row.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/presentation/fake_session.dart';

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
  _Gate([this.state = const ProfileGateInitial()]);
  @override
  final ProfileGateState state;
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

Future<void> _pump(
  WidgetTester tester,
  Locale locale, {
  UserSessionCubit? session,
  ProfileGateState? gate,
}) async {
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
              BlocProvider<UserSessionCubit>.value(
                value: session ?? _Session(),
              ),
              BlocProvider<ProfileGateCubit>.value(
                value: gate == null ? _Gate() : _Gate(gate),
              ),
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

/// The upsell card, word for word. The subtitle and the first teaser are the
/// Phase 4 copy pass's (`15-wording-table.md` §2): no likes, no "match".
const _upsell = {
  'ar': [
    'ارتقِ لعضوية التميز',
    'افتح ميزات قِران كلها، وابدأ رحلتك نحو الزواج مع خطّابتك',
    'رصيد أكبر من الاهتمام، وخطّابتك ترتّب كل خطوة بعده',
    'تبادل الصور بأمان وسرية تامة',
    'اكتشف الباقات',
  ],
  'en': [
    'Upgrade to Premium',
    "Unlock all of Qeran's features and start your journey to marriage with your matchmaker",
    'More interests, and your matchmaker arranges every step after',
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

    testWidgets('the upsell card says the copy pass\'s wording [$lang]', (
      tester,
    ) async {
      await _pump(tester, locale);

      for (final line in _upsell[lang]!) {
        expect(find.text(line), findsOneWidget, reason: line);
      }
    });
  }

  // Security: the hero photo carries the session's token to our server only.
  for (final (where, url, headers) in [
    ('our server', ourImageUrl, fakeSessionBearer),
    ('another host', foreignImageUrl, null),
  ]) {
    testWidgets('the hero photo on $where', (tester) async {
      await _pump(
        tester,
        const Locale('en'),
        session: FakeSession(),
        gate: ProfileGateResolved(
          ProfileStatus.visible,
          name: 'Huda',
          photoUrl: url,
        ),
      );

      final hero = find.byType(CachedNetworkImage);
      expect(tester.widget<CachedNetworkImage>(hero).httpHeaders, headers);
    });
  }
}
