import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_option.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_question.dart';
import 'package:qeran/features/discovery/domain/entities/filter_question_type.dart';
import 'package:qeran/features/discovery/domain/filter_question_screening.dart';

/// One screening function, both apps. The matchmaker used to drop an
/// unrenderable `unknown` question silently while the user app logged it (the
/// step-2 D7 miss); these tests are what make that impossible to reintroduce,
/// since a per-app copy can no longer disagree.
DiscoveryFilterQuestion _q(
  int id,
  FilterQuestionType type, {
  bool isRange = false,
  List<DiscoveryFilterOption>? options,
}) => DiscoveryFilterQuestion(
  id: id,
  label: 'q$id',
  type: type,
  isRange: isRange,
  options: options,
);

const _someOptions = [DiscoveryFilterOption(value: 'a', display: 'A')];

void main() {
  FilterScreening screen(List<DiscoveryFilterQuestion> all) =>
      screenFilterQuestions(all: all, logTag: 'TEST');

  group('what survives screening', () {
    test('every option-bearing and text type is kept', () {
      final out = screen([
        _q(1, FilterQuestionType.select, options: _someOptions),
        _q(2, FilterQuestionType.radio, options: _someOptions),
        _q(3, FilterQuestionType.checkbox, options: _someOptions),
        _q(4, FilterQuestionType.interests, options: _someOptions),
        _q(5, FilterQuestionType.text),
      ]);

      expect(out.kept.map((q) => q.id), [1, 2, 3, 4, 5]);
      expect(out.unknownWithoutOptions, isEmpty);
      expect(out.rangeTypeWithoutFlag, isEmpty);
    });

    test('isRange is checked FIRST — any type may be a slider', () {
      final out = screen([
        _q(1, FilterQuestionType.date, isRange: true),
        _q(5, FilterQuestionType.height, isRange: true),
        _q(6, FilterQuestionType.weight, isRange: true),
        _q(9, FilterQuestionType.unknown, isRange: true),
      ]);

      expect(out.kept.map((q) => q.id), [1, 5, 6, 9]);
      expect(out.rangeTypeWithoutFlag, isEmpty);
      expect(
        out.unknownWithoutOptions,
        isEmpty,
        reason: 'a flagged range never needs options',
      );
    });

    test('input order is preserved — screening does not reorder', () {
      // sortedFilterQuestions runs after this, so screening must not pre-empt it.
      final out = screen([
        _q(9, FilterQuestionType.text),
        _q(1, FilterQuestionType.text),
        _q(5, FilterQuestionType.text),
      ]);
      expect(out.kept.map((q) => q.id), [9, 1, 5]);
    });

    test('an empty input screens to three empty lists', () {
      final out = screen(const []);
      expect(out.kept, isEmpty);
      expect(out.unknownWithoutOptions, isEmpty);
      expect(out.rangeTypeWithoutFlag, isEmpty);
    });
  });

  group('unknown-type reporting (the D7 parity fix)', () {
    test('unknown WITH options is kept and not reported', () {
      final out = screen([
        _q(7, FilterQuestionType.unknown, options: _someOptions),
      ]);
      expect(out.kept.map((q) => q.id), [7]);
      expect(out.unknownWithoutOptions, isEmpty);
    });

    test('unknown with a null options field is dropped AND reported', () {
      final out = screen([_q(8, FilterQuestionType.unknown)]);
      expect(out.kept, isEmpty);
      expect(out.unknownWithoutOptions, [8]);
    });

    test('unknown with an EMPTY options list is dropped AND reported', () {
      // Distinct wire shape from null, same verdict — the log text differs so
      // the dashboard can tell which it sent.
      final out = screen([
        _q(9, FilterQuestionType.unknown, options: const []),
      ]);
      expect(out.kept, isEmpty);
      expect(out.unknownWithoutOptions, [9]);
    });

    test('one entry per offender, in input order, and nothing else', () {
      final out = screen([
        _q(8, FilterQuestionType.unknown),
        _q(7, FilterQuestionType.unknown, options: _someOptions),
        _q(9, FilterQuestionType.unknown, options: const []),
        _q(1, FilterQuestionType.select, options: _someOptions),
      ]);
      expect(out.unknownWithoutOptions, [8, 9]);
      expect(out.kept.map((q) => q.id), [7, 1]);
    });
  });

  group('range-type-without-flag reporting', () {
    test('date / height / weight without isRange are dropped AND reported', () {
      final out = screen([
        _q(1, FilterQuestionType.date),
        _q(5, FilterQuestionType.height),
        _q(6, FilterQuestionType.weight),
      ]);
      expect(out.kept, isEmpty);
      expect(out.rangeTypeWithoutFlag, [1, 5, 6]);
    });

    test('having options does not rescue a range type', () {
      // There is no single-value control for these, so options are irrelevant.
      final out = screen([
        _q(5, FilterQuestionType.height, options: _someOptions),
      ]);
      expect(out.kept, isEmpty);
      expect(out.rangeTypeWithoutFlag, [5]);
    });

    test('the two report lists never overlap', () {
      final out = screen([
        _q(1, FilterQuestionType.date),
        _q(8, FilterQuestionType.unknown),
      ]);
      expect(out.rangeTypeWithoutFlag, [1]);
      expect(out.unknownWithoutOptions, [8]);
    });
  });

  test('a full mixed payload screens exactly as before the extraction', () {
    // The regression guard for the extraction itself: this is the union of what
    // both cubits' private copies used to keep.
    final out = screen([
      _q(1, FilterQuestionType.date, isRange: true),
      _q(2, FilterQuestionType.date),
      _q(3, FilterQuestionType.select, options: _someOptions),
      _q(4, FilterQuestionType.unknown),
      _q(5, FilterQuestionType.unknown, options: _someOptions),
      _q(6, FilterQuestionType.text),
      _q(7, FilterQuestionType.weight),
    ]);

    expect(out.kept.map((q) => q.id), [1, 3, 5, 6]);
    expect(out.unknownWithoutOptions, [4]);
    expect(out.rangeTypeWithoutFlag, [2, 7]);
  });
}
