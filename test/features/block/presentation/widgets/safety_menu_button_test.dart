import 'package:qeran/core/utils/app_snackbar.dart';
import 'package:qeran/core/utils/widgets/qeran_snack_bar_widget.dart';
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/datasources/shared_pref_service.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/core/services/google_sign_in_service.dart';
import 'package:qeran/core/services/storage_service.dart';
import 'package:qeran/features/auth/domain/entities/user_entity.dart';
import 'package:qeran/features/auth/presentation/auth_form_memo.dart';
import 'package:qeran/features/auth/presentation/blocs/user_session/user_session_cubit.dart';
import 'package:qeran/features/block/domain/usecases/block_user_usecase.dart';
import 'package:qeran/features/block/presentation/blocs/block_action_cubit.dart';
import 'package:qeran/features/block/presentation/widgets/safety_menu_button.dart';
import 'package:qeran/generated/locale_keys.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockBlockUser extends Mock implements BlockUserUseCase {}

class _MockStorage extends Mock implements StorageService {}

class _MockPrefs extends Mock implements SharedPrefService {}

class _MockGoogle extends Mock implements GoogleSignInService {}

/// A profile's block never goes through Community's call.
Future<Either<Failure, void>> _wrongPath(String _) =>
    throw StateError('a profile blocked through Community');

/// The app's session, signed in as [user].
void _signIn(UserEntity user) => sl.registerSingleton<UserSessionCubit>(
  UserSessionCubit(
    secureStorage: _MockStorage(),
    sharedPrefs: _MockPrefs(),
    googleSignIn: _MockGoogle(),
    formMemo: AuthFormMemo(),
  )..onAuthenticated(user),
);

/// Keys come back as their own text, so rows are found by key.
class _KeysLoader extends AssetLoader {
  const _KeysLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

final _navigator = GlobalKey<NavigatorState>();

/// A profile pushed over a home route, with the ⋮ in it; [popped] receives
/// what the profile returns.
Future<void> _pumpProfile(
  WidgetTester tester, {
  required void Function(Object?) popped,
}) async {
  await tester.pumpWidget(EasyLocalization(
    supportedLocales: const [Locale('en')],
    startLocale: const Locale('en'),
    path: 'assets/translations',
    assetLoader: const _KeysLoader(),
    child: Builder(
      builder: (ctx) => MaterialApp(
        navigatorKey: _navigator,
        builder: (context, child) => AppSnackBarHost(child: child!),
        locale: ctx.locale,
        supportedLocales: ctx.supportedLocales,
        localizationsDelegates: ctx.localizationDelegates,
        home: const Scaffold(),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  _navigator.currentState!
      .push(MaterialPageRoute<Object?>(
        builder: (_) => const Scaffold(
          body: Center(child: SafetyMenuButton(targetUserId: 'user-9')),
        ),
      ))
      .then(popped);
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.more_vert));
  await tester.pumpAndSettle();
}

void main() {
  late _MockBlockUser blockUser;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    blockUser = _MockBlockUser();
    sl.registerFactoryParam<BlockActionCubit, BlockOrigin, void>(
      (origin, _) => BlockActionCubit(
        block: origin == BlockOrigin.profile ? blockUser.call : _wrongPath,
      ),
    );
  });
  tearDown(sl.reset);

  testWidgets('⋮ opens Report, then Block in the danger colour', (tester) async {
    await _pumpProfile(tester, popped: (_) {});

    final report = find.text(LocaleKeys.report_action_report_user);
    final block = find.text(LocaleKeys.block_action_block);
    expect(report, findsOneWidget);
    expect(block, findsOneWidget);
    expect(tester.getTopLeft(report).dy, lessThan(tester.getTopLeft(block).dy));
    expect(tester.widget<Text>(block).style?.color, QeranColors.danger);
    expect(tester.widget<Text>(report).style?.color, QeranColors.wine);
  });

  testWidgets('Block asks first; cancelling blocks nobody', (tester) async {
    await _pumpProfile(tester, popped: (_) {});

    await tester.tap(find.text(LocaleKeys.block_action_block));
    await tester.pumpAndSettle();
    expect(find.text(LocaleKeys.block_confirm_title), findsOneWidget);

    await tester.tap(find.text(LocaleKeys.common_cancel));
    await tester.pumpAndSettle();

    expect(find.text(LocaleKeys.block_confirm_title), findsNothing);
    verifyNever(() => blockUser(any()));
  });

  testWidgets('confirming blocks the user and closes the profile with their id',
      (tester) async {
    when(() => blockUser('user-9')).thenAnswer((_) async => const Right(unit));
    Object? result;
    await _pumpProfile(tester, popped: (value) => result = value);

    await tester.tap(find.text(LocaleKeys.block_action_block));
    await tester.pumpAndSettle();
    await tester.tap(find.text(LocaleKeys.block_confirm_button));
    await tester.pumpAndSettle();

    verify(() => blockUser('user-9')).called(1);
    expect(result, 'user-9');
    expect(find.byType(QeranSnackBarWidget), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // the toast's timers
  });

  testWidgets('a block that fails says so, and the profile stays', (
    tester,
  ) async {
    when(() => blockUser('user-9')).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'errors.timeout')),
    );
    Object? result = 'untouched';
    await _pumpProfile(tester, popped: (value) => result = value);

    await tester.tap(find.text(LocaleKeys.block_action_block));
    await tester.pumpAndSettle();
    await tester.tap(find.text(LocaleKeys.block_confirm_button));
    await tester.pumpAndSettle();

    expect(result, 'untouched');
    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byType(QeranSnackBarWidget), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // the toast's timers
  });

  testWidgets('a matchmaker gets Report only — never Block (D40, §0.4)', (
    tester,
  ) async {
    _signIn(
      const UserEntity(id: 'mm-1', name: 'هدى', email: '', role: 'Moderator'),
    );

    await _pumpProfile(tester, popped: (_) {});

    expect(find.text(LocaleKeys.report_action_report_user), findsOneWidget);
    expect(find.text(LocaleKeys.block_action_block), findsNothing);
  });

  testWidgets('a member still gets both', (tester) async {
    _signIn(const UserEntity(id: 'u-1', name: 'ديما', email: '', role: 'User'));

    await _pumpProfile(tester, popped: (_) {});

    expect(find.text(LocaleKeys.block_action_block), findsOneWidget);
  });
}
