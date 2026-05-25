import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/domain/entities/placement_item.dart';
import 'package:qeran/features/discovery/domain/entities/placement_item_type.dart';
import 'package:qeran/features/discovery/domain/entities/placement_value.dart';
import 'package:qeran/features/discovery/presentation/widgets/discovery_inside_chips.dart';

PlacementItem _item(int qid, dynamic display) => PlacementItem(
      questionId: qid,
      question: 'q-$qid',
      type: PlacementItemType.select,
      value: const PlacementSingle('v'),
      display: display is List
          ? PlacementMulti(display.cast())
          : PlacementSingle(display as String),
    );

void main() {
  group('DiscoveryInsideChips', () {
    testWidgets('renders nothing for an empty item list', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: DiscoveryInsideChips(items: []),
        ),
      ));
      expect(find.byType(Wrap), findsNothing);
    });

    testWidgets('renders one chip per item with display text', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DiscoveryInsideChips(items: [
            _item(5, '175 سم'),
            _item(4, '60 كيلو'),
          ]),
        ),
      ));
      expect(find.text('175 سم'), findsOneWidget);
      expect(find.text('60 كيلو'), findsOneWidget);
    });

    testWidgets('joins multi values with Arabic comma', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DiscoveryInsideChips(items: [
            _item(12, ['Arabic', 'English']),
          ]),
        ),
      ));
      expect(find.text('Arabic، English'), findsOneWidget);
    });
  });
}
