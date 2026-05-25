import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/domain/entities/placement_item.dart';
import 'package:qeran/features/discovery/domain/entities/placement_item_type.dart';
import 'package:qeran/features/discovery/domain/entities/placement_value.dart';
import 'package:qeran/features/discovery/presentation/widgets/_chip_display.dart';

PlacementItem _single(PlacementItemType type, String display) => PlacementItem(
      questionId: 0,
      question: 'q',
      type: type,
      value: const PlacementSingle('v'),
      display: PlacementSingle(display),
    );

PlacementItem _multi(PlacementItemType type, List<String> display) =>
    PlacementItem(
      questionId: 0,
      question: 'q',
      type: type,
      value: const PlacementSingle('v'),
      display: PlacementMulti(display),
    );

void main() {
  group('chipDisplayPure', () {
    test('appends Arabic kg suffix for weight when provided', () {
      final out = chipDisplayPure(
        _single(PlacementItemType.weight, '70'),
        unitKg: 'كيلو',
        unitCm: 'سم',
      );
      expect(out, '70 كيلو');
    });

    test('appends Arabic cm suffix for height when provided', () {
      final out = chipDisplayPure(
        _single(PlacementItemType.height, '175'),
        unitKg: 'كيلو',
        unitCm: 'سم',
      );
      expect(out, '175 سم');
    });

    test('appends English kg suffix for weight when provided', () {
      final out = chipDisplayPure(
        _single(PlacementItemType.weight, '70'),
        unitKg: 'kg',
        unitCm: 'cm',
      );
      expect(out, '70 kg');
    });

    test('returns display as-is for radio/select types', () {
      expect(
        chipDisplayPure(
          _single(PlacementItemType.radio, 'عازب'),
          unitKg: 'كيلو',
          unitCm: 'سم',
        ),
        'عازب',
      );
      expect(
        chipDisplayPure(
          _single(PlacementItemType.select, 'السعودية'),
          unitKg: 'كيلو',
          unitCm: 'سم',
        ),
        'السعودية',
      );
    });

    test('joins multi values with the Arabic comma + space', () {
      final out = chipDisplayPure(
        _multi(PlacementItemType.checkbox, ['العربية', 'الإنجليزية']),
      );
      expect(out, 'العربية، الإنجليزية');
    });

    test('omits suffix for weight/height when unit string is null', () {
      expect(
        chipDisplayPure(_single(PlacementItemType.weight, '70')),
        '70',
      );
      expect(
        chipDisplayPure(_single(PlacementItemType.height, '175')),
        '175',
      );
    });
  });
}
