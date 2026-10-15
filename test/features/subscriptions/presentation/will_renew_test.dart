import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/features/likes/presentation/widgets/photo_exchange_limit_sheet.dart';
import 'package:qeran/features/subscriptions/data/models/current_subscription_model.dart';
import 'package:qeran/features/subscriptions/domain/entities/current_subscription.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';
import 'package:qeran/features/subscriptions/presentation/widgets/subscription_status_block.dart';

import '../../../core/shipped_strings_rig.dart';
import 'widgets/subscription_widget_rig.dart';

class _MockCurrent extends Mock implements CurrentSubscriptionCubit {}

/// The shipped `<section>.<key>` in [lang], without its `{date}`.
String _s(String lang, String section, String key) =>
    (((jsonDecode(File('assets/translations/$lang.json').readAsStringSync())
                    as Map<String, dynamic>)[section]
                as Map<String, dynamic>)[key]
            as String)
        .replaceFirst('{date}', '')
        .trim();

/// Run 11: `/current`'s `willRenew`. True: «يتجدّد في», no «ينتهي اشتراكك
/// قريباً», no «تجديد الاشتراك». False (a manual grant): «ينتهي في», and the
/// photo-exchange sheet says the plan ends instead of promising a renewal.
/// Live since 2026-10-15, so «ساري حتى» is gone: a response without it reads
/// as won't renew.
void main() {
  setUpAll(initShippedStrings);

  group('the model', () {
    bool parsed(Map<String, dynamic> extra) =>
        CurrentSubscriptionModel.fromJson({
          'expiresAt': '2026-11-01T00:00:00Z',
          ...extra,
        }).toEntity().willRenew;

    test('true and false as sent', () {
      expect(parsed({'willRenew': true}), isTrue);
      expect(parsed({'willRenew': false}), isFalse);
    });

    test('absent, null or not a bool: won\'t renew', () {
      expect(parsed({}), isFalse);
      expect(parsed({'willRenew': null}), isFalse);
      expect(parsed({'willRenew': 'yes'}), isFalse);
    });
  });

  for (final lang in const ['ar', 'en']) {
    final locale = Locale(lang);
    String sub(String key) => _s(lang, 'subscriptions', key);
    String likes(String key) => _s(lang, 'likes', key);

    group('«اشتراكي» [$lang]', () {
      Future<void> pump(WidgetTester tester, CurrentSubscription s) async {
        tester.view.physicalSize = const Size(400, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final current = _MockCurrent();
        when(() => current.state).thenReturn(CurrentSubscriptionLoaded(s));
        when(() => current.stream).thenAnswer((_) => const Stream.empty());
        await pumpShippedStrings(
          tester,
          locale,
          child: SingleChildScrollView(
            child: BlocProvider<CurrentSubscriptionCubit>.value(
              value: current,
              child: const SubscriptionStatusBlock(),
            ),
          ),
        );
      }

      const soon = Duration(days: 3);

      testWidgets('renews: «يتجدّد في», no notice, no renew', (tester) async {
        await pump(tester, subscriptionWith(willRenew: true, expiresIn: soon));

        expect(find.textContaining(sub('status_renews_on')), findsOneWidget);
        expect(find.textContaining(sub('status_ends_on')), findsNothing);
        expect(find.text(sub('expiring_title')), findsNothing);
        expect(find.text(sub('renew_subscription')), findsNothing);
        expect(find.text(sub('upgrade_cta')), findsOneWidget);
      });

      testWidgets('won\'t renew: «ينتهي في», the notice, renew', (
        tester,
      ) async {
        await pump(tester, subscriptionWith(willRenew: false, expiresIn: soon));

        expect(find.textContaining(sub('status_ends_on')), findsOneWidget);
        expect(find.textContaining(sub('status_renews_on')), findsNothing);
        expect(find.text(sub('expiring_title')), findsOneWidget);
        expect(find.text(sub('renew_subscription')), findsOneWidget);
      });

      testWidgets('not sent: as won\'t renew, the notice, renew', (
        tester,
      ) async {
        await pump(tester, subscriptionWith(expiresIn: soon));

        expect(find.textContaining(sub('status_ends_on')), findsOneWidget);
        expect(find.textContaining(sub('status_renews_on')), findsNothing);
        expect(find.text(sub('expiring_title')), findsOneWidget);
        expect(find.text(sub('renew_subscription')), findsOneWidget);
      });

      testWidgets('far from the end, won\'t renew: renew stays', (
        tester,
      ) async {
        await pump(tester, subscriptionWith(willRenew: false));

        expect(find.text(sub('expiring_title')), findsNothing);
        expect(find.text(sub('renew_subscription')), findsOneWidget);
      });
    });

    group('the photo-exchange limit sheet [$lang]', () {
      Future<void> pump(WidgetTester tester, CurrentSubscription s) async {
        tester.view.physicalSize = const Size(400, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await pumpShippedStrings(
          tester,
          locale,
          child: PhotoExchangeLimitSheet(subscription: s, onUpgrade: () {}),
        );
      }

      final renews = likes('matches_photo_exchange_limit_renewal');
      final ends = likes('matches_photo_exchange_limit_ends');
      final promise = likes('matches_photo_exchange_limit_subtitle');

      testWidgets('won\'t renew: the plan ends, no renewal promise', (
        tester,
      ) async {
        await pump(tester, subscriptionWith(willRenew: false));

        expect(find.textContaining(ends), findsOneWidget);
        expect(find.textContaining(renews), findsNothing);
        expect(find.text(promise), findsNothing);
      });

      testWidgets('renews: renews on, and the promise', (tester) async {
        await pump(tester, subscriptionWith(willRenew: true));

        expect(find.textContaining(renews), findsOneWidget);
        expect(find.textContaining(ends), findsNothing);
        expect(find.text(promise), findsOneWidget);
      });
    });
  }
}
