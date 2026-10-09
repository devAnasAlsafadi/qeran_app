import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/widgets/qeran_confirm_dialog.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/profile/presentation/blocs/share_with_matchmaker/share_with_matchmaker_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/share_with_matchmaker/share_with_matchmaker_state.dart';
import 'package:qeran/features/profile/presentation/widgets/share_with_matchmaker_button.dart';

import '../../../../core/shipped_strings_rig.dart';

class _MockShare extends Mock implements ShareWithMatchmakerCubit {}

/// «اسأل خطّابتي عن هذا الملف»: it asks first, and only a confirmed ask
/// shares the profile. E3 moved the ask onto the design system's
/// `QeranConfirmDialog`.
void main() {
  setUpAll(initShippedStrings);

  late _MockShare cubit;

  setUp(() {
    cubit = _MockShare();
    when(() => cubit.state).thenReturn(
      const ShareWithMatchmakerState(
        resolved: true,
        conversationId: 12,
        isSharing: false,
        event: ShareEvent.none,
        eventVersion: 0,
      ),
    );
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.resolveMatchmaker()).thenAnswer((_) async {});
    when(() => cubit.share(any())).thenAnswer((_) async {});
    when(() => cubit.close()).thenAnswer((_) async {});
    sl.registerFactory<ShareWithMatchmakerCubit>(() => cubit);
  });

  tearDown(sl.reset);

  Future<void> openAsk(WidgetTester tester) async {
    await pumpShippedStrings(
      tester,
      const Locale('en'),
      child: const Center(child: ShareWithMatchmakerButton(userId: 'u-7')),
    );
    await tester.tap(find.text('Ask my matchmaker about this profile'));
    await tester.pumpAndSettle();
    expect(find.text('Share with your matchmaker?'), findsOneWidget);
  }

  testWidgets('cancelling shares nothing', (tester) async {
    await openAsk(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => cubit.share(any()));
  });

  testWidgets('confirming shares the profile', (tester) async {
    await openAsk(tester);
    await tester.tap(find.text('Share'));
    await tester.pumpAndSettle();

    verify(() => cubit.share('u-7')).called(1);
  });

  testWidgets('the ask is the design system\'s dialog', (tester) async {
    await openAsk(tester);

    expect(find.byType(QeranConfirmDialog), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
