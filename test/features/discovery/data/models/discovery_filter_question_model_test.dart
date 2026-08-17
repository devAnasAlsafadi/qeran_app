import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/data/models/discovery_filter_question_model.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_option.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_question.dart';
import 'package:qeran/features/discovery/domain/entities/filter_question_type.dart';

void main() {
  group('DiscoveryFilterQuestionModel — backend range fields', () {
    test('parses height with isRange/minValue/maxValue/unit', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 5,
        'question': 'الطول',
        'type': 'height',
        'isRange': true,
        'minValue': 140,
        'maxValue': 210,
        'unit': 'سم',
        'options': null,
      }).toEntity();
      expect(e.id, 5);
      expect(e.type, FilterQuestionType.height);
      expect(e.isRange, isTrue);
      expect(e.minValue, 140);
      expect(e.maxValue, 210);
      expect(e.unit, 'سم');
      expect(e.options, isNull);
      expect(e.effectiveMin, 140);
      expect(e.effectiveMax, 210);
    });

    test('parses weight with backend unit "كيلو"', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 6,
        'question': 'الوزن',
        'type': 'weight',
        'isRange': true,
        'minValue': 40,
        'maxValue': 150,
        'unit': 'كيلو',
        'options': null,
      }).toEntity();
      expect(e.type, FilterQuestionType.weight);
      expect(e.unit, 'كيلو');
      expect(e.effectiveMin, 40);
      expect(e.effectiveMax, 150);
    });

    test('parses date as age range with unit "سنة"', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 1,
        'question': 'العمر',
        'type': 'date',
        'isRange': true,
        'minValue': 18,
        'maxValue': 60,
        'unit': 'سنة',
        'options': null,
      }).toEntity();
      expect(e.type, FilterQuestionType.date);
      expect(e.isRange, isTrue);
      expect(e.minValue, 18);
      expect(e.maxValue, 60);
      expect(e.unit, 'سنة');
    });

    test('range with missing min/max/unit falls back per type', () {
      // Height with no backend metadata → 50..200, no unit forced.
      final h = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 5,
        'question': 'الطول',
        'type': 'height',
        'isRange': true,
      }).toEntity();
      expect(h.effectiveMin, 50);
      expect(h.effectiveMax, 200);
      expect(h.unit, isNull);

      // Date defaults to 18..80.
      final d = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 1,
        'question': 'العمر',
        'type': 'date',
        'isRange': true,
      }).toEntity();
      expect(d.effectiveMin, 18);
      expect(d.effectiveMax, 80);
    });
  });

  group('DiscoveryFilterQuestionModel — non-range types', () {
    test('parses select with options', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 11,
        'question': 'الجنسية',
        'type': 'select',
        'isRange': false,
        'options': [
          {'value': 'Saudi', 'display': 'سعودي'},
          {'value': 'Other', 'display': 'أخرى'},
        ],
      }).toEntity();
      expect(e.type, FilterQuestionType.select);
      expect(e.isRange, isFalse);
      expect(e.options!.length, 2);
      expect(e.options!.first.value, 'Saudi');
      expect(e.options!.first.display, 'سعودي');
    });

    test('parses radio', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 18,
        'question': 'الحالة الاجتماعية',
        'type': 'radio',
        'isRange': false,
        'options': [
          {'value': 'Single', 'display': 'عازب'},
        ],
      }).toEntity();
      expect(e.type, FilterQuestionType.radio);
    });

    test('parses checkbox', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 21,
        'question': 'لغات',
        'type': 'checkbox',
        'isRange': false,
        'options': [
          {'value': 'AR', 'display': 'العربية'},
          {'value': 'EN', 'display': 'الإنجليزية'},
        ],
      }).toEntity();
      expect(e.type, FilterQuestionType.checkbox);
      expect(e.options!.length, 2);
    });

    test('parses interests', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 22,
        'question': 'اهتمامات',
        'type': 'interests',
        'isRange': false,
        'options': [
          {'value': 'Honest', 'display': 'صادق'},
        ],
      }).toEntity();
      expect(e.type, FilterQuestionType.interests);
    });

    test('parses text', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 30,
        'question': 'اسم',
        'type': 'text',
        'isRange': false,
        'options': null,
      }).toEntity();
      expect(e.type, FilterQuestionType.text);
      expect(e.options, isNull);
    });
  });

  group('DiscoveryFilterQuestionModel — resilience', () {
    test('unknown wire type maps to FilterQuestionType.unknown', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 99,
        'question': 'سؤال جديد',
        'type': 'futureXYZ',
        'isRange': false,
        'options': [
          {'value': 'A', 'display': 'أ'},
        ],
      }).toEntity();
      expect(e.type, FilterQuestionType.unknown);
      expect(e.options!.single.value, 'A');
    });

    test('missing isRange defaults to false', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 50,
        'question': 'x',
        'type': 'select',
      }).toEntity();
      expect(e.isRange, isFalse);
    });

    test('empty json parses without crash', () {
      final m = DiscoveryFilterQuestionModel.fromJson(const {});
      expect(m.questionId, 0);
      expect(m.question, '');
      expect(m.toEntity().type, FilterQuestionType.unknown);
      expect(m.isRange, isFalse);
    });

    test('case-insensitive type mapping', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 1,
        'type': 'CHECKBOX',
      }).toEntity();
      expect(e.type, FilterQuestionType.checkbox);
    });
  });

  // Tariq's dashboard control fields. Parsed and carried to the entity here;
  // nothing READS them yet (steps 9-11 consume them). Absence is the expected
  // state until the backend rollout lands, so it must stay silent and null —
  // null is what lets the renderer keep its current inference.
  group('DiscoveryFilterQuestionModel — dashboard control fields', () {
    test('a full payload round-trips all four fields to the entity', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 11,
        'question': 'الجنسية',
        'type': 'select',
        'isRange': false,
        'displayPriority': 2,
        'isSearchable': true,
        'isMultiSelect': false,
        'options': [
          {'value': 'Saudi', 'display': 'سعودي', 'displayPriority': 1},
          {'value': 'Other', 'display': 'أخرى', 'displayPriority': 9},
        ],
      }).toEntity();

      expect(e.displayPriority, 2);
      expect(e.isSearchable, isTrue);
      expect(e.isMultiSelect, isFalse);
      expect(e.options!.map((o) => o.displayPriority), [1, 9]);
    });

    test('absent fields land as null on both entities, not as defaults', () {
      // The pre-rollout payload. `isMultiSelect: null` must NOT read as false —
      // false is an explicit dashboard choice, null means "keep inferring".
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 18,
        'question': 'الحالة الاجتماعية',
        'type': 'radio',
        'isRange': false,
        'options': [
          {'value': 'Single', 'display': 'عازب'},
        ],
      }).toEntity();

      expect(e.displayPriority, isNull);
      expect(e.isSearchable, isNull);
      expect(e.isMultiSelect, isNull);
      expect(e.options!.single.displayPriority, isNull);
    });

    test('displayPriority tolerates numeric strings and doubles', () {
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 11,
        'displayPriority': '3',
        'options': [
          {'value': 'a', 'display': 'A', 'displayPriority': 4.0},
        ],
      }).toEntity();

      expect(e.displayPriority, 3);
      expect(e.options!.single.displayPriority, 4);
    });

    test('an unparseable displayPriority degrades to null, never throws', () {
      // Was a hard `as num?` cast on the sibling fields; these would have been
      // raw TypeErrors past the repository's exception mapping.
      for (final raw in <Object>['high', true, <int>[1], <String, int>{}]) {
        final e = DiscoveryFilterQuestionModel.fromJson({
          'questionId': 11,
          'displayPriority': raw,
        }).toEntity();
        expect(e.displayPriority, isNull, reason: 'raw=$raw');
      }
    });

    test('bool flags coerce strings and 0/1, and reject garbage as null', () {
      DiscoveryFilterQuestion parse(Object? searchable, Object? multi) =>
          DiscoveryFilterQuestionModel.fromJson({
            'questionId': 11,
            'isSearchable': searchable,
            'isMultiSelect': multi,
          }).toEntity();

      expect(parse('true', 'false').isSearchable, isTrue);
      expect(parse('true', 'false').isMultiSelect, isFalse);
      expect(parse('TRUE', 'False').isSearchable, isTrue);
      expect(parse('TRUE', 'False').isMultiSelect, isFalse);
      expect(parse(1, 0).isSearchable, isTrue);
      expect(parse(1, 0).isMultiSelect, isFalse);
      // Garbage stays null rather than collapsing to false — the difference
      // decides whether the client infers or obeys.
      expect(parse('yes', 'maybe').isSearchable, isNull);
      expect(parse('yes', 'maybe').isMultiSelect, isNull);
      expect(parse(<int>[], null).isSearchable, isNull);
    });

    test('copyWith keeps the new fields and can replace the options list', () {
      // Step 11's sort helper relies on exactly this: swap options for a
      // reordered list, carry everything else through untouched.
      final e = DiscoveryFilterQuestionModel.fromJson(const {
        'questionId': 11,
        'question': 'الجنسية',
        'type': 'select',
        'displayPriority': 2,
        'isSearchable': true,
        'isMultiSelect': true,
        'options': [
          {'value': 'b', 'display': 'B', 'displayPriority': 2},
          {'value': 'a', 'display': 'A', 'displayPriority': 1},
        ],
      }).toEntity();

      final sorted = e.copyWith(options: e.options!.reversed.toList());

      expect(sorted.options!.map((o) => o.value), ['a', 'b']);
      expect(sorted.displayPriority, 2);
      expect(sorted.isSearchable, isTrue);
      expect(sorted.isMultiSelect, isTrue);
      expect(sorted.id, 11);
      expect(sorted.label, 'الجنسية');
      expect(sorted.type, FilterQuestionType.select);
      expect(e.options!.map((o) => o.value), ['b', 'a'], reason: 'no mutation');

      expect(
        e.options!.first.copyWith(display: 'B2'),
        const DiscoveryFilterOption(
          value: 'b',
          display: 'B2',
          displayPriority: 2,
        ),
      );
    });
  });
}
