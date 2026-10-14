import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/subscriptions/domain/entities/current_subscription.dart';
import 'package:qeran/features/subscriptions/domain/usecases/get_current_subscription_usecase.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/activation_pending.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_cubit.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';

import '../../../core/memory_storage.dart';
import 'widgets/subscription_widget_rig.dart';

class _MockGetCurrent extends Mock implements GetCurrentSubscriptionUseCase {}

const _key = StorageKeys.subscriptionActivationSince;

CurrentSubscription _active() => subscriptionWith(allowed: 5, used: 0);

/// C5 (Q26): a purchase the store confirmed says "activating" — never None —
/// until `/current` shows it active, across restarts; after ten minutes it
/// says so. Re-reads are scripted with zero delays.
void main() {
  late _MockGetCurrent getCurrent;
  late MemoryStorage prefs;
  late List<Either<Failure, CurrentSubscription?>> answers;
  late int reads;

  setUp(() {
    getCurrent = _MockGetCurrent();
    prefs = MemoryStorage();
    answers = [];
    reads = 0;
    when(() => getCurrent()).thenAnswer((_) async {
      final i = reads++;
      return answers[i < answers.length ? i : answers.length - 1];
    });
  });

  CurrentSubscriptionCubit build({DateTime Function()? now}) =>
      CurrentSubscriptionCubit(
        getCurrent: getCurrent,
        activation: ActivationPending(
          prefs: prefs,
          now: now,
          reReads: const [Duration.zero, Duration.zero, Duration.zero],
        ),
      );

  test('confirmed, the server not caught up: activating, never None', () async {
    answers = [const Right(null)];
    final cubit = build();

    await cubit.onStoreConfirmed();

    expect(cubit.state, isA<CurrentSubscriptionActivating>());
    expect(reads, 1 + 3, reason: 'one read, then each re-read');
    expect(prefs.values[_key], isA<int>(), reason: 'kept for a restart');
    await cubit.close();
  });

  test('the first active /current settles it and forgets the mark', () async {
    answers = [const Right(null), Right(_active())];
    final cubit = build();

    await cubit.onStoreConfirmed();

    expect(cubit.state, isA<CurrentSubscriptionLoaded>());
    expect(reads, 2, reason: 'no re-read after it settled');
    expect(prefs.values.containsKey(_key), isFalse);
    await cubit.close();
  });

  test('a failed read while activating stays activating', () async {
    answers = [const Left(ServerFailure(message: 'errors.server'))];
    final cubit = build();

    await cubit.onStoreConfirmed();

    expect(cubit.state, isA<CurrentSubscriptionActivating>());
    await cubit.close();
  });

  test('after a restart, still activating — not None', () async {
    answers = [const Right(null)];
    prefs.values[_key] = DateTime.now().millisecondsSinceEpoch;
    final cubit = build();

    await cubit.hydrate();

    expect(cubit.state, isA<CurrentSubscriptionActivating>());
    await cubit.close();
  });

  test('ten minutes on, it is overdue', () async {
    answers = [const Right(null)];
    // Kept to the millisecond, as the phone keeps it.
    final since = DateTime.fromMillisecondsSinceEpoch(
      DateTime.now()
          .subtract(const Duration(minutes: 10))
          .millisecondsSinceEpoch,
    );
    prefs.values[_key] = since.millisecondsSinceEpoch;
    final cubit = build();

    await cubit.hydrate();

    expect(
      cubit.state,
      CurrentSubscriptionActivating(since: since, overdue: true),
    );
    await cubit.close();
  });

  // Its own clock and the test zone's fake timers: a slow machine can't
  // reach the mark before the first look (it once did, on the wall clock).
  testWidgets('turns overdue on its own at the ten-minute mark', (
    tester,
  ) async {
    answers = [const Right(null)];
    var now = DateTime.fromMillisecondsSinceEpoch(1760000000000);
    final almost = now.subtract(
      ActivationPending.overdueAfter - const Duration(seconds: 1),
    );
    prefs.values[_key] = almost.millisecondsSinceEpoch;
    final cubit = build(now: () => now);

    await cubit.hydrate();
    await tester.pump(const Duration(milliseconds: 999));
    now = now.add(const Duration(milliseconds: 999));
    expect((cubit.state as CurrentSubscriptionActivating).overdue, isFalse);

    now = now.add(const Duration(milliseconds: 1));
    await tester.pump(const Duration(milliseconds: 1));

    expect((cubit.state as CurrentSubscriptionActivating).overdue, isTrue);
    await cubit.close();
  });

  test('an upgrade keeps showing the active plan, and settles', () async {
    answers = [Right(_active())];
    final cubit = build();
    await cubit.hydrate();

    await cubit.onStoreConfirmed();

    expect(cubit.state, isA<CurrentSubscriptionLoaded>());
    expect(prefs.values.containsKey(_key), isFalse);
    await cubit.close();
  });

  test(
    'an account change forgets it; sign-out removes the kept mark',
    () async {
      answers = [const Right(null)];
      final cubit = build();
      await cubit.onStoreConfirmed();

      cubit.clear();
      prefs.values.remove(_key); // what sign-out does with the account's keys
      await cubit.hydrate();

      expect(cubit.state, isA<CurrentSubscriptionNone>());
      expect(StorageKeys.accountKeys, contains(_key));
      await cubit.close();
    },
  );
}
