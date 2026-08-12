import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/widgets/qeran_button.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/matchmaker/users/domain/entities/image_request_status.dart';
import 'package:qeran/features/matchmaker/users/domain/repositories/matchmaker_user_actions_repository.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/approve_user_usecase.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/approve_user_image_usecase.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/reject_user_usecase.dart';
import 'package:qeran/features/matchmaker/users/domain/usecases/request_image_user_usecase.dart';
import 'package:qeran/features/matchmaker/users/presentation/blocs/matchmaker_user_actions_cubit.dart';
import 'package:qeran/features/matchmaker/users/presentation/widgets/matchmaker_review_action_sheet.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// #5 — the request-photo button reads the persisted `imageRequestStatus`.
///
/// none → offer the request · pending → awaiting, disabled (so the matchmaker
/// can't nag a user who simply hasn't uploaded yet) · approved → nothing left
/// to ask for, the button drops out.

class _StubActionsRepository implements MatchmakerUserActionsRepository {
  @override
  Future<Either<Failure, String>> approveImage({
    required String userId,
    required String imageId,
  }) async => const Right('ok');

  @override
  Future<Either<Failure, String>> approve(String userId) async =>
      const Right('ok');

  @override
  Future<Either<Failure, String>> reject({
    required String userId,
    required String reason,
  }) async => const Right('ok');

  @override
  Future<Either<Failure, String>> requestImage(String userId) async =>
      const Right('ok');
}

/// No translations — `context.tr(key)` falls back to the key itself, which is
/// what these assertions match on.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

Future<void> _openSheet(
  WidgetTester tester, {
  required bool hasNoImage,
  required MatchmakerImageRequestStatus status,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ar')],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          home: Builder(
            builder: (inner) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showMatchmakerReviewSheet(
                    inner,
                    userId: 'u1',
                    hasNoImage: hasNoImage,
                    imageRequestStatus: status,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

QeranButton _buttonWithLabel(WidgetTester tester, String label) =>
    tester.widget<QeranButton>(
      find.byWidgetPredicate((w) => w is QeranButton && w.label == label),
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final repo = _StubActionsRepository();
    sl.registerFactoryParam<MatchmakerUserActionsCubit, String, void>(
      (userId, _) => MatchmakerUserActionsCubit(
        userId: userId,
        approve: ApproveUserUseCase(repo),
        reject: RejectUserUseCase(repo),
        requestImage: RequestImageUserUseCase(repo),
        approveImage: ApproveUserImageUseCase(repo),
      ),
    );
  });

  tearDownAll(() => sl.reset());

  const requestKey = LocaleKeys.matchmaker_profile_action_request_image;
  const awaitingKey = LocaleKeys.matchmaker_profile_request_image_awaiting;

  testWidgets('none → the request button is offered and enabled', (
    tester,
  ) async {
    await _openSheet(
      tester,
      hasNoImage: true,
      status: MatchmakerImageRequestStatus.none,
    );

    expect(find.text(requestKey), findsOneWidget);
    expect(find.text(awaitingKey), findsNothing);
    expect(_buttonWithLabel(tester, requestKey).onPressed, isNotNull);
  });

  testWidgets('pending → awaiting label, and it cannot be pressed again', (
    tester,
  ) async {
    await _openSheet(
      tester,
      hasNoImage: true,
      status: MatchmakerImageRequestStatus.pending,
    );

    expect(find.text(awaitingKey), findsOneWidget);
    expect(find.text(requestKey), findsNothing);
    // The whole point: a second request must be impossible.
    expect(_buttonWithLabel(tester, awaitingKey).onPressed, isNull);
  });

  testWidgets('approved → no photo button at all', (tester) async {
    await _openSheet(
      tester,
      hasNoImage: true,
      status: MatchmakerImageRequestStatus.approved,
    );

    expect(find.text(requestKey), findsNothing);
    expect(find.text(awaitingKey), findsNothing);
  });

  testWidgets('a user who already has a photo never sees it', (tester) async {
    await _openSheet(
      tester,
      hasNoImage: false,
      status: MatchmakerImageRequestStatus.none,
    );

    expect(find.text(requestKey), findsNothing);
    expect(find.text(awaitingKey), findsNothing);
    // …but the sheet itself did open.
    expect(find.text(LocaleKeys.matchmaker_users_action_approve), findsOneWidget);
  });
}
