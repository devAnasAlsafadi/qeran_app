import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/features/block/presentation/blocs/block_action_cubit.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_profile.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_card.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_name_age_row.dart';

import '../../../../core/shipped_fonts_rig.dart';
import '../../../../core/shipped_strings_rig.dart';

const _member = DiscoveryProfile(
  id: 'member-7',
  name: 'Huda',
  age: 27,
  images: [],
  matchingScore: 0,
  placements: [],
);

/// Apple 1.2 on Suggestions (run 6): the card has the full profile's ⋮ at the
/// end of the name line — the same Report / Block — and a block hands the
/// member's id back to the deck instead of closing a screen it doesn't have.
void main() {
  setUpAll(initShippedStrings);

  late List<String> blockedOnServer;

  setUp(() {
    blockedOnServer = [];
    sl.registerFactoryParam<BlockActionCubit, BlockOrigin, void>(
      (_, _) => BlockActionCubit(
        block: (id) async {
          blockedOnServer.add(id);
          return const Right<Failure, void>(null);
        },
      ),
    );
  });

  tearDown(() async {
    AppSnackBar.debugReset();
    await sl.reset();
  });

  Future<void> pumpCard(
    WidgetTester tester,
    String lang, {
    ValueChanged<String>? onBlocked,
  }) => pumpShippedStrings(
    tester,
    Locale(lang),
    builder: (_, child) => AppSnackBarHost(child: child!),
    child: SizedBox(
      height: 420,
      child: DiscoveryImagePanel(
        profile: _member,
        height: 420,
        activeFilterCount: 0,
        onBlocked: onBlocked,
      ),
    ),
  );

  for (final lang in const ['ar', 'en']) {
    testWidgets('the ⋮ on the name line opens Report and Block [$lang]', (
      tester,
    ) async {
      await pumpCard(tester, lang, onBlocked: (_) {});

      final menu = find.descendant(
        of: find.byType(DiscoveryNameAgeRow),
        matching: find.byIcon(Icons.more_vert),
      );
      expect(menu, findsOneWidget);

      await tester.tap(menu);
      await tester.pumpAndSettle();

      expect(find.text(shipped(lang, 'report.action_report_user')), findsOne);
      expect(find.text(shipped(lang, 'block.action_block')), findsOneWidget);
    });
  }

  testWidgets('a block hands the id back; nothing is popped', (tester) async {
    final handedBack = <String>[];
    await pumpCard(tester, 'ar', onBlocked: handedBack.add);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text(shipped('ar', 'block.action_block')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(shipped('ar', 'block.confirm_button')));
    await tester.pumpAndSettle();

    expect(blockedOnServer, ['member-7']);
    expect(handedBack, ['member-7']);
    // Still on the home route: the card is the deck's to remove.
    expect(find.byType(DiscoveryImagePanel), findsOneWidget);
    expect(find.text(shipped('ar', 'block.success')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('without a deck to leave, no ⋮', (tester) async {
    await pumpCard(tester, 'ar');

    expect(find.byIcon(Icons.more_vert), findsNothing);
  });
}
