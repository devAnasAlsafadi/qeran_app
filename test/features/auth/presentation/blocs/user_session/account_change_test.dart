import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/constants/storage_keys.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/features/community/presentation/blocs/composer/community_gate.dart';
import 'package:qeran/features/profile/domain/entities/my_profile.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_state.dart';
import 'package:qeran/features/subscriptions/domain/entities/current_subscription.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/current/current_subscription_state.dart';

import 'account_change_rig.dart';

/// Two accounts on one phone: whatever the app kept for the first — its
/// profile gate, counts, subscription, read marks, flags and prefs — is gone
/// before the second can see it, whether the first signed out, deleted the
/// account, or the second simply signed in.
void main() {
  late AccountChangeRig rig;

  setUp(() => rig = AccountChangeRig());
  tearDown(() => rig.close());

  /// The member's shell has run: the gate knows them, a dot shows, the
  /// subscription is read, a row is read, the banner was dismissed and a
  /// photo window is open.
  Future<void> memberWasHere() async {
    rig.buildHolders();
    rig.session.onAuthenticated(member);
    when(
      () => rig.getBadges(),
    ).thenAnswer((_) async => const Right(BadgeCounts({'likes': 3})));
    await rig.gate.refresh();
    await rig.badges.refresh();
    await rig.subscription.refresh(force: true);
    await rig.reads.markRead(41);
    rig.banner.hide();
    rig.clock.start(9, 60);
    expect(communityGateOf(rig.gate.state), CommunityGate.name);
  }

  void expectNothingOfTheMember() {
    expect(rig.gate.state, const ProfileGateInitial());
    expect(communityGateOf(rig.gate.state), isNull);
    expect(rig.badges.state, const BadgeCounts.empty());
    expect(rig.subscription.state, const CurrentSubscriptionInitial());
    expect(rig.reads.state.isRead(41), isFalse);
    expect(rig.banner.isHidden, isFalse);
    expect(rig.clock.remaining(9), 0);
  }

  test('a member signs out: nothing of theirs is left', () async {
    await memberWasHere();

    await rig.session.signOut();

    expectNothingOfTheMember();
  });

  test('a matchmaker signs in after a member: the composer is asked '
      'nothing on the member\'s behalf', () async {
    await memberWasHere();

    rig.session.onAuthenticated(matchmaker);

    expectNothingOfTheMember();
  });

  test('a matchmaker signs out: her counts go with the session alone, as '
      'her account screen no longer clears them', () async {
    rig.buildHolders();
    rig.session.onAuthenticated(matchmaker);
    when(() => rig.getBadges()).thenAnswer(
      (_) async => const Right(
        BadgeCounts({
          'communityCommentsUnread': 2,
          'communityReportsPending': 1,
        }),
      ),
    );
    await rig.badges.refresh();
    expect(rig.badges.state, isNot(const BadgeCounts.empty()));

    await rig.session.signOut();

    expect(rig.badges.state, const BadgeCounts.empty());
  });

  test('the account is deleted: nothing of it is left', () async {
    await memberWasHere();

    await rig.session.wipeAllLocalData();

    expectNothingOfTheMember();
  });

  test('the same account confirmed again (the OTP after registering) '
      'keeps its state', () async {
    await memberWasHere();

    rig.session.onAuthenticated(member);

    expect(communityGateOf(rig.gate.state), CommunityGate.name);
    expect(rig.banner.isHidden, isTrue);
  });

  test('reads in flight for the member land nowhere after sign-out', () async {
    rig.buildHolders();
    rig.session.onAuthenticated(member);
    final profile = Completer<Either<Failure, MyProfile>>();
    final counts = Completer<Either<Failure, BadgeCounts>>();
    final current = Completer<Either<Failure, CurrentSubscription?>>();
    when(() => rig.getProfile()).thenAnswer((_) => profile.future);
    when(() => rig.getBadges()).thenAnswer((_) => counts.future);
    when(() => rig.getCurrent()).thenAnswer((_) => current.future);
    final reads = [
      rig.gate.refresh(),
      rig.badges.refresh(),
      rig.subscription.refresh(force: true),
    ];

    await rig.session.signOut();
    profile.complete(Right(memberProfile()));
    counts.complete(const Right(BadgeCounts({'likes': 3})));
    current.complete(const Right(null));
    await Future.wait(reads);

    expect(rig.gate.state, const ProfileGateInitial());
    expect(rig.badges.state, const BadgeCounts.empty());
    expect(rig.subscription.state, isA<CurrentSubscriptionInitial>());
  });

  test('the app forgets only once the token is gone, so nothing reloads '
      'as the member on the way out', () async {
    var tokenGone = false;
    bool? tokenGoneWhenForgotten;
    when(() => rig.secure.remove(StorageKeys.token)).thenAnswer((_) async {
      tokenGone = true;
    });
    rig.scope.hold(Object(), (_) => tokenGoneWhenForgotten = tokenGone);

    await rig.session.signOut();

    expect(tokenGoneWhenForgotten, isTrue);
  });

  test('sign-out removes what the account left in prefs: a half-done '
      'questionnaire, its gender, the read marks', () async {
    await rig.session.signOut();

    for (final key in [
      StorageKeys.questionnaireDraft,
      StorageKeys.gender,
      StorageKeys.signedOath,
      StorageKeys.notifReadWatermark,
      StorageKeys.notifReadIds,
      StorageKeys.matchmakerNotifReadWatermark,
    ]) {
      verify(() => rig.prefs.remove(key)).called(1);
    }
  });
}
