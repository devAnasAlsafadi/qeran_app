import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/data/models/placement_value_model.dart';
import 'package:qeran/features/discovery/domain/entities/placement_value.dart';

void main() {
  group('PlacementValueModel.fromJson', () {
    test('String → PlacementSingle', () {
      final v = PlacementValueModel.fromJson('Engineer');
      expect(v, isA<PlacementSingle>());
      expect((v as PlacementSingle).value, 'Engineer');
    });

    test('empty String → PlacementSingle("")', () {
      final v = PlacementValueModel.fromJson('');
      expect(v, equals(const PlacementSingle('')));
    });

    test('List<String> → PlacementMulti preserving order', () {
      final v = PlacementValueModel.fromJson(['Funny', 'Ambitious', 'Family']);
      expect(v, isA<PlacementMulti>());
      expect(
        (v as PlacementMulti).values,
        ['Funny', 'Ambitious', 'Family'],
      );
    });

    test('mixed-type list → coerces every element to String', () {
      final v = PlacementValueModel.fromJson(['a', 1, true, null]);
      expect(v, isA<PlacementMulti>());
      expect(
        (v as PlacementMulti).values,
        ['a', '1', 'true', 'null'],
      );
    });

    test('empty list → PlacementMulti([])', () {
      final v = PlacementValueModel.fromJson(<dynamic>[]);
      expect(v, equals(const PlacementMulti([])));
    });

    test('null → PlacementSingle("")', () {
      expect(PlacementValueModel.fromJson(null), const PlacementSingle(''));
    });

    test('unexpected shape (int) → PlacementSingle("") + warning log', () {
      // Just verify the fallback. The warning is fire-and-forget through
      // AppLogger; not asserted here.
      expect(PlacementValueModel.fromJson(42), const PlacementSingle(''));
    });
  });
}
