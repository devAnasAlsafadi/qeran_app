import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/design_system/tokens/qeran_colors.dart';
import 'package:qeran/core/design_system/widgets/qeran_count_badge.dart';

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  testWidgets('renders the count as written below the cap', (tester) async {
    await _pump(tester, const QeranCountBadge(count: 7));

    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('renders the cap exactly at the boundary', (tester) async {
    await _pump(tester, const QeranCountBadge(count: 99));

    expect(find.text('99'), findsOneWidget);
    expect(find.text('99+'), findsNothing);
  });

  // A bell pools every kind of notification, so the number can run away. Past
  // the cap it is a nudge, not a figure worth reading precisely — and an
  // unbounded one would widen the pill past the icon it belongs to.
  testWidgets('caps above the boundary', (tester) async {
    await _pump(tester, const QeranCountBadge(count: 100));

    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('the cap is configurable', (tester) async {
    await _pump(tester, const QeranCountBadge(count: 50, cap: 9));

    expect(find.text('9+'), findsOneWidget);
  });

  // Identity rule: unread is an invitation, not a fault. Red is reserved for
  // danger, and this must never drift back to it.
  testWidgets('is gold by default, never danger', (tester) async {
    await _pump(tester, const QeranCountBadge(count: 3));

    final decoration =
        tester.widget<Container>(find.byType(Container)).decoration
            as BoxDecoration;
    expect(decoration.color, QeranColors.gold);
    expect(decoration.color, isNot(QeranColors.danger));
  });
}
