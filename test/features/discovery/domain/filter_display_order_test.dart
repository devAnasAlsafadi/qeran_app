import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_option.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_question.dart';
import 'package:qeran/features/discovery/domain/entities/filter_question_type.dart';
import 'package:qeran/features/discovery/domain/filter_display_order.dart';

/// One helper, both apps — the two filter cubits call it on load, so these are
/// the only tests that need to exist for the ordering rule.
DiscoveryFilterQuestion _q(
  int id, {
  int? displayPriority,
  List<DiscoveryFilterOption>? options,
}) => DiscoveryFilterQuestion(
  id: id,
  label: 'q$id',
  type: FilterQuestionType.select,
  isRange: false,
  displayPriority: displayPriority,
  options: options,
);

DiscoveryFilterOption _o(String value, {int? displayPriority}) =>
    DiscoveryFilterOption(
      value: value,
      display: value.toUpperCase(),
      displayPriority: displayPriority,
    );

List<int> _ids(List<DiscoveryFilterQuestion> qs) =>
    qs.map((q) => q.id).toList();

void main() {
  group('effectiveOrderKey', () {
    test('a set priority is its own key; absent becomes the sentinel', () {
      expect(_q(1, displayPriority: 7).effectiveOrderKey, 7);
      expect(_q(1).effectiveOrderKey, kUnprioritizedOrderKey);
      expect(_o('a', displayPriority: 7).effectiveOrderKey, 7);
      expect(_o('a').effectiveOrderKey, kUnprioritizedOrderKey);
    });

    test('the sentinel is above any priority a dashboard would assign', () {
      expect(kUnprioritizedOrderKey, greaterThan(1000000));
      // A 0 default would have done the opposite of what E1 asks.
      expect(_q(1).effectiveOrderKey, greaterThan(_q(2, displayPriority: 0).effectiveOrderKey));
    });
  });

  group('sortedFilterQuestions — questions', () {
    test('lower displayPriority sorts before higher', () {
      final out = sortedFilterQuestions([
        _q(30, displayPriority: 30),
        _q(10, displayPriority: 10),
        _q(20, displayPriority: 20),
      ]);
      expect(_ids(out), [10, 20, 30]);
    });

    test('null displayPriority sorts LAST, behind every set priority', () {
      final out = sortedFilterQuestions([
        _q(1), // null — arrives first, must end up last
        _q(2, displayPriority: 99),
        _q(3), // null
        _q(4, displayPriority: 1),
      ]);
      expect(_ids(out), [4, 2, 1, 3]);
    });

    test('equal priorities keep their original relative order', () {
      // Dart's List.sort is not stable, so without the index tie-break this is
      // exactly where the order would become arbitrary.
      final out = sortedFilterQuestions([
        _q(5, displayPriority: 1),
        _q(4, displayPriority: 1),
        _q(3, displayPriority: 1),
        _q(2, displayPriority: 0),
      ]);
      expect(_ids(out), [2, 5, 4, 3]);
    });

    test('an all-null payload comes back exactly as the server sent it', () {
      final out = sortedFilterQuestions([_q(9), _q(3), _q(7), _q(1)]);
      expect(_ids(out), [9, 3, 7, 1]);
    });

    test('the same input yields the same output on every run', () {
      // Stability is only meaningful if it is deterministic across calls, not
      // just within one.
      final input = [
        _q(1, displayPriority: 2),
        _q(2, displayPriority: 2),
        _q(3),
        _q(4, displayPriority: 2),
        _q(5),
        _q(6, displayPriority: 1),
      ];
      final first = _ids(sortedFilterQuestions(input));
      for (var run = 0; run < 20; run++) {
        expect(_ids(sortedFilterQuestions(input)), first, reason: 'run $run');
      }
      expect(first, [6, 1, 2, 4, 3, 5]);
    });

    test('the input list is never mutated', () {
      // List.sort works in place, and these lists come from the datasource.
      final input = [_q(1, displayPriority: 9), _q(2, displayPriority: 1)];
      sortedFilterQuestions(input);
      expect(_ids(input), [1, 2]);
    });

    test('an unmodifiable input list is accepted', () {
      final out = sortedFilterQuestions(
        List.unmodifiable([_q(1, displayPriority: 9), _q(2, displayPriority: 1)]),
      );
      expect(_ids(out), [2, 1]);
    });

    test('an empty list is fine', () {
      expect(sortedFilterQuestions(const []), isEmpty);
    });
  });

  group('sortedFilterQuestions — options within a question', () {
    test('options sort by their OWN displayPriority', () {
      final out = sortedFilterQuestions([
        _q(
          1,
          options: [
            _o('c', displayPriority: 3),
            _o('a', displayPriority: 1),
            _o('b', displayPriority: 2),
          ],
        ),
      ]);
      expect(out.single.options!.map((o) => o.value), ['a', 'b', 'c']);
    });

    test('null-priority options sort last, ties keep original order', () {
      final out = sortedFilterQuestions([
        _q(
          1,
          options: [
            _o('x'), // null
            _o('y', displayPriority: 5),
            _o('z'), // null
            _o('w', displayPriority: 5),
          ],
        ),
      ]);
      expect(out.single.options!.map((o) => o.value), ['y', 'w', 'x', 'z']);
    });

    test('question order and option order are applied together', () {
      final out = sortedFilterQuestions([
        _q(2, displayPriority: 2, options: [_o('b', displayPriority: 2), _o('a', displayPriority: 1)]),
        _q(1, displayPriority: 1, options: [_o('d', displayPriority: 2), _o('c', displayPriority: 1)]),
      ]);
      expect(_ids(out), [1, 2]);
      expect(out.first.options!.map((o) => o.value), ['c', 'd']);
      expect(out.last.options!.map((o) => o.value), ['a', 'b']);
    });

    test('the copyWith round-trip preserves every other field', () {
      // The sort replaces `options` via copyWith (E2), so a dropped field here
      // would silently lose a dashboard flag.
      final original = DiscoveryFilterQuestion(
        id: 11,
        label: 'الجنسية',
        type: FilterQuestionType.radio,
        isRange: true,
        minValue: 140,
        maxValue: 210,
        unit: 'سم',
        displayPriority: 4,
        isSearchable: false,
        isMultiSelect: true,
        options: [_o('b', displayPriority: 2), _o('a', displayPriority: 1)],
      );

      final sorted = sortedFilterQuestions([original]).single;

      expect(sorted.options!.map((o) => o.value), ['a', 'b']);
      expect(sorted.copyWith(options: original.options), original);
    });

    test('null and single-item option lists pass through untouched', () {
      final out = sortedFilterQuestions([
        _q(1), // options == null
        _q(2, options: [_o('only')]),
        _q(3, options: const []),
      ]);
      expect(out[0].options, isNull);
      expect(out[1].options!.single.value, 'only');
      expect(out[2].options, isEmpty);
    });
  });
}
