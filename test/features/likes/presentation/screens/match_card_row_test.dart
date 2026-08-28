import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/theme/qeran_theme.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/chat/domain/usecases/get_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/send_text_message_usecase.dart';
import 'package:qeran/features/chat/domain/usecases/share_profile_usecase.dart';
import 'package:qeran/features/likes/domain/entities/formal_step_outcome.dart';
import 'package:qeran/features/likes/domain/entities/formal_step_status.dart';
import 'package:qeran/features/likes/domain/entities/match_stage.dart';
import 'package:qeran/features/likes/domain/entities/pending_formal_step.dart';
import 'package:qeran/features/likes/domain/usecases/accept_formal_step_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/accept_photo_exchange_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/cancel_case_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/reject_formal_step_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/reject_photo_exchange_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/request_formal_step_usecase.dart';
import 'package:qeran/features/likes/domain/usecases/request_photo_exchange_usecase.dart';
import 'package:qeran/features/likes/presentation/blocs/match_actions_cubit.dart';
import 'package:qeran/features/likes/presentation/blocs/matchmaker_inquiry_cubit.dart';
import 'package:qeran/features/likes/presentation/screens/match_card_row.dart';
import 'package:qeran/features/profile/presentation/blocs/profile_gate/profile_gate_cubit.dart';

import '../widgets/match_card_copy_harness.dart';

/// The wiring between a match card and the cubit that acts on it.
///
/// This row is where two id namespaces meet four lines apart: the LIKE id the
/// card and the case are keyed by, and `pendingFormalStep.id`, which keys a
/// request INSIDE that case. Both are ints, so posting one where the other
/// belongs compiles, type-checks, reviews cleanly and reaches a real endpoint
/// with a real id belonging to something else.
///
/// A REAL [MatchActionsCubit] over mocked use cases rather than a mock cubit —
/// the project has no `bloc_test`, and the use-case boundary is the honest
/// place to read the id off anyway: it is what the request would actually
/// carry.
///
/// Only testable at all because sub-step 5d lifted this row out of the
/// `itemBuilder` closure it used to live in inside `matches_section`.

class _MockRequestPx extends Mock implements RequestPhotoExchangeUseCase {}

class _MockAcceptPx extends Mock implements AcceptPhotoExchangeUseCase {}

class _MockRejectPx extends Mock implements RejectPhotoExchangeUseCase {}

class _MockRequestFormalStep extends Mock implements RequestFormalStepUseCase {}

class _MockAcceptFormalStep extends Mock implements AcceptFormalStepUseCase {}

class _MockRejectFormalStep extends Mock implements RejectFormalStepUseCase {}

class _MockCancelCase extends Mock implements CancelCaseUseCase {}

class _MockProfileGate extends Mock implements ProfileGateCubit {}

class _MockGetMyMatchmaker extends Mock implements GetMyMatchmakerUseCase {}

class _MockShareProfile extends Mock implements ShareProfileUseCase {}

class _MockSendText extends Mock implements SendTextMessageUseCase {}

void main() {
  late _MockCancelCase cancelCase;
  late MatchActionsCubit actions;
  late MatchmakerInquiryCubit inquiry;

  setUpAll(loadShippedFonts);

  setUp(() {
    cancelCase = _MockCancelCase();
    final profileGate = _MockProfileGate();
    when(() => profileGate.isGated).thenReturn(false);
    actions = MatchActionsCubit(
      requestPhotoExchange: _MockRequestPx(),
      acceptPhotoExchange: _MockAcceptPx(),
      rejectPhotoExchange: _MockRejectPx(),
      requestFormalStep: _MockRequestFormalStep(),
      acceptFormalStep: _MockAcceptFormalStep(),
      rejectFormalStep: _MockRejectFormalStep(),
      cancelCase: cancelCase,
      profileGate: profileGate,
      reloadMatches: () async {},
    );
    inquiry = MatchmakerInquiryCubit(
      getMyMatchmaker: _MockGetMyMatchmaker(),
      shareProfile: _MockShareProfile(),
      sendText: _MockSendText(),
    );
  });

  tearDown(() async {
    await actions.close();
    await inquiry.close();
  });

  Future<void> pumpRow(WidgetTester tester, {required card}) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        startLocale: const Locale('ar'),
        path: 'unused',
        assetLoader: const DiskLoader(),
        child: Builder(
          builder: (context) => MaterialApp(
            theme: QeranTheme.light(const Locale('ar')),
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: MultiBlocProvider(
              providers: [
                BlocProvider<MatchActionsCubit>.value(value: actions),
                BlocProvider<MatchmakerInquiryCubit>.value(value: inquiry),
              ],
              child: Scaffold(
                body: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: kListInset),
                  child: MatchCardRow(
                    card: card,
                    onOpenGallery: () {},
                    onOpenProfile: () {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the cancel X posts the LIKE id, not a request id inside it', (
    tester,
  ) async {
    when(() => cancelCase(any())).thenAnswer(
      (_) async => const Right<Failure, CaseCancelOutcome>(
        CaseCancelSuccess(serverMessage: ''),
      ),
    );
    // A card whose formal-step id differs from its like id, and where the
    // step is waiting on THEM — so the X is shown and both ids are live in
    // the same build.
    final card = copyCard(
      MatchStage.photosExchanged,
      pendingFormalStep: PendingFormalStep(
        id: 77,
        likeRequestId: 1,
        status: FormalStepStatus.pending,
        remainingSeconds: 3600,
        createdAt: DateTime.utc(2026),
        expiresAt: DateTime.utc(2099),
        direction: 'Sent',
        requestedByMe: true,
        canAccept: false,
        canReject: false,
      ),
    );

    await pumpRow(tester, card: card);
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(shipped(const Locale('ar'), 'matches_case_end_confirm_action')),
    );
    await tester.pumpAndSettle();

    verify(() => cancelCase(1)).called(1);
    verifyNever(() => cancelCase(77));
  });

  // The same namespace question on the way back. The row asks the cubit
  // "is THIS card cancelling?" and has to ask with the id it sent — looking
  // the in-flight set up by the formal-step id would leave the X live and
  // tappable through the whole call.
  testWidgets('an in-flight cancel is read back under the same id', (
    tester,
  ) async {
    final gate = Completer<Either<Failure, CaseCancelOutcome>>();
    when(() => cancelCase(any())).thenAnswer((_) => gate.future);

    await pumpRow(tester, card: copyCard(MatchStage.photosExchanged));
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(shipped(const Locale('ar'), 'matches_case_end_confirm_action')),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byType(CircularProgressIndicator),
      findsOneWidget,
      reason: 'the card shows nothing happening while the call is in flight',
    );
    expect(find.byIcon(Icons.close_rounded), findsNothing);

    gate.complete(
      const Right<Failure, CaseCancelOutcome>(
        CaseCancelSuccess(serverMessage: ''),
      ),
    );
    await tester.pumpAndSettle();
  });
}
