import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_active_filters.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_selection.dart';

void main() {
  test('none narrows nothing', () {
    expect(DiscoveryActiveFilters.none.isActive, isFalse);
    expect(DiscoveryActiveFilters.none.query, isNull);
    expect(DiscoveryActiveFilters.none.selections, isEmpty);
  });

  test('a null or empty query narrows nothing', () {
    for (final query in [null, <String, String>{}]) {
      final filters = DiscoveryActiveFilters(query: query);
      expect(filters.isActive, isFalse, reason: 'query $query');
      expect(filters.query, isNull, reason: 'query $query');
    }
  });

  test('a query narrows the deck, whatever the selections say', () {
    final filters = DiscoveryActiveFilters(
      query: const {'QuestionFilters[11]': 'SA'},
    );
    expect(filters.isActive, isTrue);
    expect(filters.query, {'QuestionFilters[11]': 'SA'});
  });

  test('selections alone narrow nothing', () {
    final filters = DiscoveryActiveFilters(
      selections: const {5: RangeSelection(min: 150, max: 200)},
    );
    expect(filters.isActive, isFalse);
    expect(filters.selections, hasLength(1));
  });

  test('holds copies the caller cannot change afterwards', () {
    final query = {'QuestionFilters[11]': 'SA'};
    final selections = <int, DiscoveryFilterSelection>{
      11: const SingleValueSelection('SA'),
    };
    final filters = DiscoveryActiveFilters(
      query: query,
      selections: selections,
    );
    query.clear();
    selections.clear();

    expect(filters.query, {'QuestionFilters[11]': 'SA'});
    expect(filters.selections, hasLength(1));
    expect(() => filters.query!['x'] = 'y', throwsUnsupportedError);
  });
}
