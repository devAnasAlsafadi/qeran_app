import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_option.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_question.dart';
import 'package:qeran/features/discovery/domain/entities/discovery_filter_selection.dart';
import 'package:qeran/features/discovery/domain/entities/filter_question_type.dart';
import 'package:qeran/features/discovery/domain/filter_payload_builders.dart';
import 'package:qeran/features/discovery/domain/filter_selection_rules.dart';

/// These rules are the ONE place both apps agree on single-vs-multi. The two
/// filter cubits and the two renderers are deliberately duplicated, so pinning
/// the shared rule here is what stops the two apps from drifting apart — a
/// per-app test could pass on both sides while they disagreed.
DiscoveryFilterQuestion _q({
  int id = 11,
  FilterQuestionType type = FilterQuestionType.select,
  bool? isMultiSelect,
}) => DiscoveryFilterQuestion(
  id: id,
  label: 'q$id',
  type: type,
  isRange: false,
  isMultiSelect: isMultiSelect,
);

void main() {
  group('effectiveIsMultiSelect — the fallback when the flag is absent', () {
    test('null → every option-bearing type is multi, text is not', () {
      // The CURRENT behaviour, unchanged: the wire format has always carried
      // comma-joined values, so select/radio are multi here too.
      const multi = [
        FilterQuestionType.select,
        FilterQuestionType.radio,
        FilterQuestionType.checkbox,
        FilterQuestionType.interests,
        FilterQuestionType.unknown,
      ];
      for (final t in multi) {
        expect(_q(type: t).effectiveIsMultiSelect, isTrue, reason: t.name);
      }
      const single = [
        FilterQuestionType.text,
        FilterQuestionType.date,
        FilterQuestionType.height,
        FilterQuestionType.weight,
      ];
      for (final t in single) {
        expect(_q(type: t).effectiveIsMultiSelect, isFalse, reason: t.name);
      }
    });

    test('an explicit flag overrides the type inference in both directions', () {
      expect(
        _q(type: FilterQuestionType.checkbox, isMultiSelect: false)
            .effectiveIsMultiSelect,
        isFalse,
      );
      expect(
        _q(type: FilterQuestionType.text, isMultiSelect: true)
            .effectiveIsMultiSelect,
        isTrue,
      );
    });

    test('forbidsMultiSelect is only an EXPLICIT false, never an inferred one', () {
      expect(_q(type: FilterQuestionType.text).forbidsMultiSelect, isFalse);
      expect(_q(isMultiSelect: false).forbidsMultiSelect, isTrue);
      expect(_q(isMultiSelect: true).forbidsMultiSelect, isFalse);
    });
  });

  group('effectiveIsSearchable — the dashboard wins absolutely', () {
    // The threshold is passed in rather than read from the design system: no
    // domain or data file in this codebase imports it, and the number is a
    // "how many chips read comfortably" decision. 10 here mirrors
    // kQeranSearchableFacetThreshold; the renderer tests pin the real constant.
    DiscoveryFilterQuestion q({int optionCount = 0, bool? isSearchable}) =>
        DiscoveryFilterQuestion(
          id: 11,
          label: 'q11',
          type: FilterQuestionType.select,
          isRange: false,
          isSearchable: isSearchable,
          options: List.generate(
            optionCount,
            (i) => DiscoveryFilterOption(value: 'v$i', display: 'o$i'),
          ),
        );

    bool searchable(DiscoveryFilterQuestion question) =>
        question.effectiveIsSearchable(optionCountThreshold: 10);

    test('true forces the search box onto a TINY list', () {
      expect(searchable(q(optionCount: 2, isSearchable: true)), isTrue);
    });

    test('false forces chips onto a 300-option list', () {
      expect(searchable(q(optionCount: 300, isSearchable: false)), isFalse);
    });

    test('null falls back to the count, cutting over at > not >=', () {
      expect(searchable(q(optionCount: 10)), isFalse);
      expect(searchable(q(optionCount: 11)), isTrue);
    });

    test('a null options list is not searchable and does not throw', () {
      final noOptions = DiscoveryFilterQuestion(
        id: 30,
        label: 'q30',
        type: FilterQuestionType.text,
        isRange: false,
      );
      expect(
        noOptions.effectiveIsSearchable(optionCountThreshold: 10),
        isFalse,
      );
    });
  });

  group('nonSearchableLongLists — visibility only', () {
    DiscoveryFilterQuestion q(int id, int optionCount, bool? isSearchable) =>
        DiscoveryFilterQuestion(
          id: id,
          label: 'q$id',
          type: FilterQuestionType.select,
          isRange: false,
          isSearchable: isSearchable,
          options: List.generate(
            optionCount,
            (i) => DiscoveryFilterOption(value: 'v$i', display: 'o$i'),
          ),
        );

    List<int> flagged(List<DiscoveryFilterQuestion> qs) => nonSearchableLongLists(
      questions: qs,
      optionCountThreshold: 10,
      logTag: 'TEST',
    );

    test('one entry per over-threshold non-searchable question, no others', () {
      expect(
        flagged([
          q(1, 300, false), // flagged — the disagreement
          q(2, 300, null), // no flag sent, no disagreement
          q(3, 300, true), // agrees with the client
          q(4, 5, false), // short list, the override costs nothing
          q(5, 11, false), // flagged — just over
        ]),
        [1, 5],
      );
    });

    test('nothing is flagged when no question disagrees', () {
      expect(flagged([q(1, 5, null), q(2, 50, true)]), isEmpty);
      expect(flagged(const []), isEmpty);
    });

    test('the flag never changes what renders — it only reports', () {
      final offender = q(1, 300, false);
      flagged([offender]);
      expect(
        offender.effectiveIsSearchable(optionCountThreshold: 10),
        isFalse,
        reason: 'still chips, exactly as the dashboard asked',
      );
    });
  });

  group('collapseForbiddenMultiSelections (E4)', () {
    Map<int, DiscoveryFilterSelection> collapse(
      List<DiscoveryFilterQuestion> questions,
      Map<int, DiscoveryFilterSelection> seeded,
    ) => collapseForbiddenMultiSelections(
      questions: questions,
      seeded: seeded,
      logTag: 'TEST',
    );

    test('an explicit false collapses a 3-value seed to its first value', () {
      final out = collapse(
        [_q(isMultiSelect: false)],
        const {11: MultiValueSelection(['a', 'b', 'c'])},
      );
      expect(out[11], const SingleValueSelection('a'));
    });

    test('a one-value multi collapses too, so the next tap can toggle off', () {
      // Not cosmetic: setSingleValue only recognises a SingleValueSelection as
      // "already active", so left as a multi the chip the user taps to CLEAR
      // would be re-set instead and stay lit.
      final out = collapse(
        [_q(isMultiSelect: false)],
        const {11: MultiValueSelection(['a'])},
      );
      expect(out[11], const SingleValueSelection('a'));
    });

    test('an empty multi is dropped rather than collapsed', () {
      final out = collapse(
        [_q(isMultiSelect: false)],
        const {11: MultiValueSelection([])},
      );
      expect(out.containsKey(11), isFalse);
    });

    test('null and true flags leave the seed untouched', () {
      const seed = {11: MultiValueSelection(['a', 'b'])};
      expect(collapse([_q()], seed)[11], seed[11]);
      expect(collapse([_q(isMultiSelect: true)], seed)[11], seed[11]);
    });

    test('other selection shapes and unknown ids pass through', () {
      final out = collapse([_q(isMultiSelect: false)], const {
        11: SingleValueSelection('a'),
        5: RangeSelection(min: 1, max: 2),
        // No question 99 in the list — a stale seed must not be dropped here;
        // the payload builders already ignore selections without a question.
        99: MultiValueSelection(['x', 'y']),
      });
      expect(out[11], const SingleValueSelection('a'));
      expect(out[5], const RangeSelection(min: 1, max: 2));
      expect(out[99], const MultiValueSelection(['x', 'y']));
    });

    test('an empty seed short-circuits to an empty, mutable map', () {
      final out = collapse([_q(isMultiSelect: false)], const {});
      expect(out, isEmpty);
      out[1] = const SingleValueSelection('a'); // must not be const/unmodifiable
      expect(out, hasLength(1));
    });
  });

  group('trimmedRangeEdges (step 4)', () {
    DiscoveryFilterQuestion range({int? min, int? max}) =>
        DiscoveryFilterQuestion(
          id: 5,
          label: 'height',
          type: FilterQuestionType.height,
          isRange: true,
          minValue: min,
          maxValue: max,
        );

    ({int? from, int? to}) edges(
      DiscoveryFilterQuestion q,
      int lo,
      int hi,
    ) => trimmedRangeEdges(
      question: q,
      selection: RangeSelection(min: lo, max: hi),
      logTag: 'TEST',
    );

    test('both thumbs on the advertised bounds → nothing to send', () {
      expect(edges(range(min: 140, max: 210), 140, 210), (from: null, to: null));
    });

    test('only the moved edge is emitted, in either direction', () {
      expect(edges(range(min: 140, max: 210), 160, 210), (from: 160, to: null));
      expect(edges(range(min: 140, max: 210), 140, 180), (from: null, to: 180));
    });

    test('both moved → both emitted', () {
      expect(edges(range(min: 140, max: 210), 160, 180), (from: 160, to: 180));
    });

    test('the type defaults are the bounds when the backend sends none', () {
      // height defaults to 50..200 — the comparison must use effectiveMin/Max,
      // not the raw nullable fields.
      expect(edges(range(), 50, 200), (from: null, to: null));
      expect(edges(range(), 60, 200), (from: 60, to: null));
    });

    test('an edge BEYOND the bound trims too — the test is >, not !=', () {
      // Unreachable through the slider, but a seeded selection from a question
      // whose bounds the dashboard has since narrowed can land here.
      expect(edges(range(min: 140, max: 210), 100, 250), (from: null, to: null));
    });

    test('a range on a non-range question is refused, not trimmed', () {
      final notARange = DiscoveryFilterQuestion(
        id: 11,
        label: 'q11',
        type: FilterQuestionType.select,
        isRange: false,
      );
      expect(edges(notARange, 2, 5), (from: null, to: null));
    });

    test('an inverted range trips the debug assertion', () {
      // "Should be structurally impossible" — so it fails loudly here instead
      // of shipping a filter that can match nothing. Release builds warn and
      // skip; that branch is unreachable while asserts are enabled.
      expect(
        () => edges(range(min: 140, max: 210), 190, 150),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('the wire shape is unchanged by multi-on-single-choice', () {
    // Tariq's note: `QuestionFilters[id]` has always accepted `v1,v2,v3` and the
    // server splits on the comma regardless of the question's type. Pinned on
    // BOTH payload shapes so a future "radio must send one value" change fails
    // here rather than in the field.
    test('radio sending 3 values goes out comma-joined (user app shape)', () {
      final payload = buildDiscoveryFilterPayload(
        questions: [_q(id: 18, type: FilterQuestionType.radio)],
        selections: const {18: MultiValueSelection(['a', 'b', 'c'])},
        logTag: 'TEST',
      );
      expect(payload, {'QuestionFilters[18]': 'a,b,c'});
    });

    test('radio sending 3 values keeps the list (explore shape)', () {
      final filters = exploreQuestionFilters(
        questions: [_q(id: 18, type: FilterQuestionType.radio)],
        selections: const {18: MultiValueSelection(['a', 'b', 'c'])},
        logTag: 'TEST',
      );
      expect(filters, {
        18: ['a', 'b', 'c'],
      });
    });

    test('auditing a selection whose question is gone does not throw', () {
      expect(
        buildDiscoveryFilterPayload(
          questions: const [],
          selections: const {18: MultiValueSelection(['a', 'b'])},
          logTag: 'TEST',
        ),
        {'QuestionFilters[18]': 'a,b'},
      );
      expect(
        exploreQuestionFilters(
          questions: const [],
          selections: const {18: MultiValueSelection(['a', 'b'])},
          logTag: 'TEST',
        ),
        {
          18: ['a', 'b'],
        },
      );
    });
  });
}
