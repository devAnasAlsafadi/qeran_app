import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_profile.dart';
import 'package:qeran/features/discovery/domain/entities/placement.dart';
import 'package:qeran/features/discovery/domain/entities/placement_code.dart';
import 'package:qeran/features/discovery/domain/entities/placement_item.dart';
import 'package:qeran/features/discovery/domain/entities/placement_item_type.dart';
import 'package:qeran/features/discovery/domain/entities/placement_value.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_card.dart';

void main() {
  testWidgets('image overlay never overflows when viewport height collapses', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 360,
              height: 140,
              child: DiscoveryImagePanel(
                profile: _profile,
                showOverlayActions: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('رنا الشمري 22'), findsOneWidget);
    expect(find.text('صاحبة عمل'), findsOneWidget);
  });
}

const _profile = DiscoveryProfile(
  id: 'small-height-profile',
  name: 'رنا الشمري',
  age: 22,
  images: [],
  matchingScore: 0,
  placements: [
    Placement(
      code: PlacementCode.aboveImage,
      name: 'بيانات أساسية',
      items: [
        PlacementItem(
          questionId: 1,
          question: 'العمل',
          type: PlacementItemType.text,
          value: PlacementSingle('employed'),
          display: PlacementSingle('صاحبة عمل'),
        ),
        PlacementItem(
          questionId: 2,
          question: 'الدولة',
          type: PlacementItemType.select,
          value: PlacementSingle('saudi_arabia'),
          display: PlacementSingle('سعودية'),
        ),
        PlacementItem(
          questionId: 3,
          question: 'المدينة',
          type: PlacementItemType.select,
          value: PlacementSingle('riyadh'),
          display: PlacementSingle('الرياض'),
        ),
      ],
    ),
  ],
);
