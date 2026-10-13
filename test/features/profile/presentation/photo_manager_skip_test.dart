import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/profile/presentation/blocs/photo_manager/photo_manager_cubit.dart';
import 'package:qeran/features/profile/presentation/blocs/photo_manager/photo_manager_state.dart';
import 'package:qeran/features/profile/presentation/screens/photo_manager/photo_manager_screen.dart';

import '../../../core/shipped_strings_rig.dart';

class _MockCubit extends Mock implements PhotoManagerCubit {}

/// The photo step's «تخطي» reads in wine, like the back arrow beside it.
/// It was gold on the soft-white canvas, which the client found too faint.
void main() {
  setUpAll(initShippedStrings);

  setUp(() {
    final cubit = _MockCubit();
    when(
      () => cubit.state,
    ).thenReturn(const PhotoManagerState(mode: PhotoManagerMode.onboarding));
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(cubit.load).thenAnswer((_) async {});
    when(cubit.close).thenAnswer((_) async {});
    sl.registerFactoryParam<PhotoManagerCubit, PhotoManagerMode, void>(
      (_, _) => cubit,
    );
  });
  tearDown(() => sl.unregister<PhotoManagerCubit>());

  for (final (lang, skip) in [('ar', 'تخطي'), ('en', 'Skip')]) {
    testWidgets('$lang: «$skip» is wine', (tester) async {
      await pumpShippedStrings(
        tester,
        Locale(lang),
        child: const PhotoManagerScreen(mode: PhotoManagerMode.onboarding),
        settle: false,
      );
      final label = tester.widget<Text>(find.text(skip));
      expect(label.style?.color, QeranColors.wine);
    });
  }
}
