import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/features/badges/domain/entities/badge_counts.dart';
import 'package:qeran/features/chat/domain/entities/matchmaker_info.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/domain/usecases/get_my_matchmaker_usecase.dart';
import 'package:qeran/features/chat/presentation/blocs/my_matchmaker_cubit.dart';
import 'package:qeran/features/home/presentation/home_back_trail.dart';
import 'package:qeran/features/home/presentation/home_shell_scope.dart';
import 'package:qeran/features/home/presentation/widgets/shell_top_bar.dart';

/// Strings render as their keys, so assertions name the key they expect.
class _StubAssetLoader extends AssetLoader {
  const _StubAssetLoader();
  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async =>
      const {};
}

class _MockGetMyMatchmaker extends Mock implements GetMyMatchmakerUseCase {}

const kHuda = MatchmakerInfo(
  matchmakerId: 'm1',
  name: 'Huda',
  profileImageUrl: null,
  conversationId: 9,
);

/// A cubit that has read [outcome]; null leaves it unknown, as while the
/// first read is still in flight.
Future<MyMatchmakerCubit> matchmakerCubit(MyMatchmakerOutcome? outcome) async {
  final getMyMatchmaker = _MockGetMyMatchmaker();
  final cubit = MyMatchmakerCubit(getMyMatchmaker: getMyMatchmaker);
  addTearDown(cubit.close);
  if (outcome != null) {
    when(() => getMyMatchmaker()).thenAnswer((_) async => Right(outcome));
    await cubit.refresh();
  }
  return cubit;
}

/// The bar alone at the top of a screen, inside the shell's scope.
Future<void> pumpShellTopBar(
  WidgetTester tester, {
  required MyMatchmakerCubit matchmaker,
  BadgeCounts badges = const BadgeCounts({}),
  HomeBackTrail? trail,
  VoidCallback? followBackTrail,
  VoidCallback? onOpenChat,
  VoidCallback? onOpenInbox,
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'assets/translations',
      assetLoader: const _StubAssetLoader(),
      child: Builder(
        builder: (ctx) => MaterialApp(
          locale: ctx.locale,
          supportedLocales: ctx.supportedLocales,
          localizationsDelegates: ctx.localizationDelegates,
          home: HomeShellScope(
            openLikesTab: () {},
            openProfileTab: () {},
            openFromNotification: (_) {},
            backTrail: trail,
            followBackTrail: followBackTrail ?? () {},
            child: BlocProvider<MyMatchmakerCubit>.value(
              value: matchmaker,
              child: Scaffold(
                body: Column(
                  children: [
                    ShellTopBar(
                      badges: badges,
                      onOpenChat: onOpenChat ?? () {},
                      onOpenInbox: onOpenInbox ?? () {},
                    ),
                  ],
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
