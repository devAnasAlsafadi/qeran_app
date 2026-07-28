import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/dashboard/presentation/widgets/matchmaker_overview_tile.dart';
import 'package:qeran/features/matchmaker/interests/presentation/widgets/matchmaker_interest_card.dart';

Widget _host(TextDirection direction, Widget child) => MaterialApp(
  home: Directionality(
    textDirection: direction,
    child: Material(child: SizedBox(width: 360, height: 220, child: child)),
  ),
);

void main() {
  testWidgets('interest disclosure uses the framework-mirrored forward icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TextDirection.rtl,
        MatchmakerInterestCard(
          imageUrl: null,
          name: 'سارة',
          locked: false,
          onTap: () {},
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.chevron_right_rounded));
    expect(icon.icon?.matchTextDirection, isTrue);
  });

  testWidgets('dashboard disclosure uses the same mirrored forward icon', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TextDirection.rtl,
        MatchmakerOverviewTile(
          icon: Icons.people_outline,
          count: 3,
          label: 'المستخدمون',
          onTap: () {},
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.chevron_right_rounded));
    expect(icon.icon?.matchTextDirection, isTrue);
  });
}
