import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/tokens/qeran_radii.dart';
import 'package:qeran/core/design_system/tokens/qeran_shadows.dart';
import 'package:qeran/core/design_system/tokens/qeran_strokes.dart';
import 'package:qeran/core/design_system/widgets/qeran_bottom_nav.dart';
import 'package:qeran/core/di/injection_container.dart';
import 'package:qeran/features/badges/presentation/blocs/badges_cubit.dart';

import 'qeran_bottom_nav_rig.dart';

/// Run 11 (Anas picked A): the bar is lifted by the `eLiftUp` token, cast up
/// over the content it floats on, and edged with a hairline, in both apps and
/// both orientations. No raw shadow values.
void main() {
  final lift = QeranShadows.eLiftUp.single;

  setUp(() async {
    await sl.reset();
    sl.registerLazySingleton<BadgesCubit>(NavBadgesCubit.new);
  });

  tearDown(() async => sl.reset());

  for (final (app, nav) in [('member', memberNav), ('matchmaker', herNav)]) {
    testWidgets('$app, portrait: eLiftUp cast up, paper, hairline', (
      tester,
    ) async {
      await pumpNav(tester, 'en', nav, 0);

      final bar = tester.renderObject<RenderBox>(
        find.byKey(QeranBottomNav.barKey),
      );
      final shape = RRect.fromRectAndRadius(
        Offset.zero & bar.size,
        const Radius.circular(QeranRadii.card),
      );
      expect(
        bar,
        paints
          ..rrect(rrect: shape.shift(lift.offset), color: lift.color)
          ..rrect(rrect: shape, color: QeranColors.paper)
          ..rrect(
            color: QeranShadows.hairlineBorder,
            style: PaintingStyle.stroke,
            strokeWidth: QeranStrokes.hairline,
          ),
      );
      expect(lift.offset.dy, isNegative, reason: 'cast up, over the content');
      expect(bar, paintsExactlyCountTimes(#drawShadow, 0));
    });

    testWidgets('$app, landscape: the same token and hairline', (tester) async {
      await pumpNav(tester, 'en', nav, 0, size: const Size(800, 360));

      final box = tester.widget<DecoratedBox>(
        find.byKey(QeranBottomNav.barKey),
      );
      final decoration = box.decoration as BoxDecoration;
      expect(decoration.boxShadow, QeranShadows.eLiftUp);
      expect(
        decoration.border,
        Border.all(
          color: QeranShadows.hairlineBorder,
          width: QeranStrokes.hairline,
        ),
      );
    });
  }
}
