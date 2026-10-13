import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/domain/entities/like_request_card.dart';
import 'package:qeran/features/likes/domain/entities/like_request_status.dart';
import 'package:qeran/features/likes/presentation/widgets/like_user_card.dart';

import '../../../../core/shipped_strings_rig.dart';

/// A locked Received card (TQ16): the server keeps the member hidden and
/// leaves residence and job out on purpose, but still sends the age. The card
/// shows that age, and nothing it wasn't sent.
LikeRequestCard _locked({int? age}) => LikeRequestCard(
  likeRequestId: 1,
  profileId: '',
  name: '',
  profileImage: null,
  age: age,
  status: LikeRequestStatus.pending,
  createdAt: null,
  remainingSeconds: null,
  actions: const [],
  isLocked: true,
);

Future<void> _pump(WidgetTester tester, Locale locale, LikeRequestCard card) =>
    pumpShippedStrings(
      tester,
      locale,
      child: Scaffold(body: LikeUserCard(card: card)),
    );

void main() {
  setUpAll(initShippedStrings);

  testWidgets('Arabic: the age under the hidden name, the lock line kept', (
    tester,
  ) async {
    await _pump(tester, const Locale('ar'), _locked(age: 29));

    expect(find.text('29 سنة'), findsOneWidget);
    expect(find.byIcon(Icons.cake_outlined), findsOneWidget);
    expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    expect(find.byIcon(Icons.work_outline_rounded), findsNothing);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));
  });

  testWidgets('English: the same', (tester) async {
    await _pump(tester, const Locale('en'), _locked(age: 29));

    expect(find.text('29 years'), findsOneWidget);
  });

  testWidgets('no age sent: no facts line', (tester) async {
    await _pump(tester, const Locale('ar'), _locked());

    expect(find.byIcon(Icons.cake_outlined), findsNothing);
    expect(find.byIcon(Icons.lock_rounded), findsNWidgets(2));
  });
}
