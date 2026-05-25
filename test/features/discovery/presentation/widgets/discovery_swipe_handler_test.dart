import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_deck_animation_controller.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_swipe_handler.dart';

/// Records every drag method invoked on the controller, in order.
/// Used to assert that the swipe handler routes gestures cleanly into
/// the [DeckAnimationScope]'s controller — the controller, not the
/// handler, owns the snap-vs-eject decision now.
class _RecordingController extends DiscoveryDeckAnimationController {
  final List<String> events = [];

  @override
  void onDragStart() {
    events.add('start');
    super.onDragStart();
  }

  @override
  void onDragUpdate(double dx) {
    events.add('update');
    super.onDragUpdate(dx);
  }

  @override
  Future<void> onDragEnd({required double velocity}) async {
    events.add('end:${velocity > 0 ? '+' : (velocity < 0 ? '-' : '0')}');
    await super.onDragEnd(velocity: velocity);
  }
}

const _targetKey = Key('swipe-target');

Future<void> _pumpHandler(
  WidgetTester tester,
  DiscoveryDeckAnimationController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: DeckAnimationScope(
        notifier: controller,
        child: Scaffold(
          body: Center(
            child: DiscoverySwipeHandler(
              child: const SizedBox(
                key: _targetKey,
                width: 240,
                height: 400,
                child: ColoredBox(color: Color(0xFFCCCCCC)),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('DiscoverySwipeHandler — routes gestures to the controller', () {
    testWidgets('right fling → end event with positive velocity',
        (tester) async {
      final controller = _RecordingController();
      controller.bindDrag(
        onStart: () {},
        onUpdate: (_) {},
        onEnd: ({required velocity}) async {},
      );
      await _pumpHandler(tester, controller);

      await tester.fling(find.byKey(_targetKey), const Offset(300, 0), 1500);
      await tester.pumpAndSettle();

      expect(controller.events.first, 'start');
      expect(
        controller.events.any((e) => e == 'update'),
        isTrue,
        reason: 'expected drag updates before the end event',
      );
      expect(controller.events.last, 'end:+');
    });

    testWidgets('left fling → end event with negative velocity',
        (tester) async {
      final controller = _RecordingController();
      controller.bindDrag(
        onStart: () {},
        onUpdate: (_) {},
        onEnd: ({required velocity}) async {},
      );
      await _pumpHandler(tester, controller);

      await tester.fling(find.byKey(_targetKey), const Offset(-300, 0), 1500);
      await tester.pumpAndSettle();

      expect(controller.events.last, 'end:-');
    });

    testWidgets('slow drag → end event still fires (animator decides)',
        (tester) async {
      // Slow drags still flow through. The animator (not the gesture
      // handler) decides snap-back vs eject based on distance and
      // velocity. The handler is just a transparent adapter.
      final controller = _RecordingController();
      controller.bindDrag(
        onStart: () {},
        onUpdate: (_) {},
        onEnd: ({required velocity}) async {},
      );
      await _pumpHandler(tester, controller);

      await tester.drag(find.byKey(_targetKey), const Offset(120, 0));
      await tester.pumpAndSettle();

      expect(controller.events.first, 'start');
      expect(controller.events.last.startsWith('end:'), isTrue);
    });

    testWidgets('no scope above → handler is a no-op pass-through',
        (tester) async {
      // Defensive: production always wraps in a scope, but a bare
      // handler in a test fixture must not crash.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiscoverySwipeHandler(
              child: const SizedBox(
                key: _targetKey,
                width: 240,
                height: 400,
                child: ColoredBox(color: Color(0xFFCCCCCC)),
              ),
            ),
          ),
        ),
      );

      await tester.fling(find.byKey(_targetKey), const Offset(300, 0), 1500);
      await tester.pumpAndSettle();
    });
  });
}
