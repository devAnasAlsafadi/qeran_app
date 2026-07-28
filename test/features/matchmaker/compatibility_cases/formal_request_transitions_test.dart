import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/formal_request_status.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/widgets/matchmaker_case_labels.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// #10 — Closed and Cancelled are one negative terminal.
///
/// The backend treats `CompatibilityClosed(4)` and `CompatibilityCancelled(5)`
/// identically, so the UI offered two buttons that did the same thing. We now
/// offer ONE closure and always send `CompatibilityCancelled`; `4` survives
/// only so pre-merge cases still display.

void main() {
  group('allowedNext — one closure per stage', () {
    test('WaitingForParentAppointment → ParentsVisited | Cancelled', () {
      expect(
        FormalRequestStatus.waitingForParentAppointment.allowedNext,
        {
          FormalRequestStatus.parentsVisited,
          FormalRequestStatus.compatibilityCancelled,
        },
      );
    });

    test('ParentsVisited → SuccessfullyClosed | Cancelled', () {
      expect(
        FormalRequestStatus.parentsVisited.allowedNext,
        {
          FormalRequestStatus.successfullyClosed,
          FormalRequestStatus.compatibilityCancelled,
        },
      );
    });

    test('CompatibilityClosed is never offered as a target', () {
      // The lead regression: it used to sit in BOTH sets, producing the
      // duplicate إغلاق/إلغاء pair.
      for (final from in FormalRequestStatus.values) {
        expect(
          from.allowedNext,
          isNot(contains(FormalRequestStatus.compatibilityClosed)),
          reason: '$from must not offer CompatibilityClosed',
        );
      }
    });

    test('exactly one destructive target per actionable stage', () {
      for (final from in [
        FormalRequestStatus.waitingForParentAppointment,
        FormalRequestStatus.parentsVisited,
      ]) {
        expect(
          from.allowedNext.where(isDestructiveTarget).toList(),
          [FormalRequestStatus.compatibilityCancelled],
          reason: '$from must offer exactly one closure',
        );
      }
    });

    test('the three terminal states stay terminal', () {
      for (final terminal in [
        FormalRequestStatus.successfullyClosed,
        FormalRequestStatus.compatibilityClosed,
        FormalRequestStatus.compatibilityCancelled,
        FormalRequestStatus.unknown,
      ]) {
        expect(terminal.allowedNext, isEmpty);
        expect(terminal.isTerminal, isTrue);
      }
    });
  });

  group('what we send', () {
    test('the closure sends CompatibilityCancelled verbatim', () {
      expect(
        FormalRequestStatus.compatibilityCancelled.apiValue,
        'CompatibilityCancelled',
      );
    });

    test('CompatibilityClosed still parses back for display', () {
      // Cases closed before the merge must keep rendering.
      expect(
        FormalRequestStatus.fromString('CompatibilityClosed'),
        FormalRequestStatus.compatibilityClosed,
      );
      expect(
        formalStatusLabelKey(FormalRequestStatus.compatibilityClosed),
        isNotNull,
      );
    });
  });

  group('labels', () {
    test('both negative terminals share the one closure verb', () {
      expect(
        actionLabelKey(FormalRequestStatus.compatibilityCancelled),
        LocaleKeys.matchmaker_cases_action_close_case,
      );
      expect(
        actionLabelKey(FormalRequestStatus.compatibilityClosed),
        LocaleKeys.matchmaker_cases_action_close_case,
      );
    });

    test('the forward steps keep their own verbs', () {
      expect(
        actionLabelKey(FormalRequestStatus.parentsVisited),
        LocaleKeys.matchmaker_cases_action_parents_visited,
      );
      expect(
        actionLabelKey(FormalRequestStatus.successfullyClosed),
        LocaleKeys.matchmaker_cases_action_successfully_closed,
      );
    });
  });
}
