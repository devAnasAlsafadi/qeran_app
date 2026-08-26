import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/domain/entities/formal_request_status.dart';
import 'package:qeran/features/matchmaker/compatibility_cases/presentation/widgets/matchmaker_case_labels.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// The two negative terminals are two different outcomes again.
///
/// They were merged while the backend treated `CompatibilityClosed(4)` and
/// `CompatibilityCancelled(5)` as one state: offering both meant two buttons
/// that did the same thing, so we collapsed them and always sent `5`. The
/// server now records them differently — `4` is `Failed`, `5` is `Cancelled` —
/// and the merge became a bug: the matchmaker could report every ending as
/// merely called off, and never as having not worked out.
///
/// These pin the split. The failure they exist to catch is a silent re-merge:
/// both concepts still resolving to one wire value, or one label, in which
/// case everything still compiles and the wrong outcome is recorded forever
/// on a live case.
void main() {
  group('the two terminals are genuinely distinct', () {
    test('they are different members', () {
      expect(
        FormalRequestStatus.notSuccessful,
        isNot(FormalRequestStatus.calledOff),
      );
    });

    test('they send different wire values', () {
      expect(FormalRequestStatus.notSuccessful.apiValue, 'CompatibilityClosed');
      expect(
        FormalRequestStatus.calledOff.apiValue,
        'CompatibilityCancelled',
      );
    });

    test('they read differently to the matchmaker', () {
      expect(
        actionLabelKey(FormalRequestStatus.notSuccessful),
        isNot(actionLabelKey(FormalRequestStatus.calledOff)),
      );
      expect(
        formalStatusLabelKey(FormalRequestStatus.notSuccessful),
        isNot(formalStatusLabelKey(FormalRequestStatus.calledOff)),
      );
    });

    test('both are confirmed before they submit', () {
      expect(isDestructiveTarget(FormalRequestStatus.notSuccessful), isTrue);
      expect(isDestructiveTarget(FormalRequestStatus.calledOff), isTrue);
    });
  });

  group('allowedNext', () {
    test('WaitingForParentAppointment → ParentsVisited | calledOff', () {
      expect(
        FormalRequestStatus.waitingForParentAppointment.allowedNext,
        {
          FormalRequestStatus.parentsVisited,
          FormalRequestStatus.calledOff,
        },
      );
    });

    test('ParentsVisited → SuccessfullyClosed | notSuccessful | calledOff', () {
      expect(
        FormalRequestStatus.parentsVisited.allowedNext,
        {
          FormalRequestStatus.successfullyClosed,
          FormalRequestStatus.notSuccessful,
          FormalRequestStatus.calledOff,
        },
      );
    });

    // The narrowing Tariq made server-side, mirrored so the button is never
    // offered rather than offered and rejected. Before the families have met
    // there is no outcome to report.
    test('notSuccessful is offered only after the visit', () {
      final offering = FormalRequestStatus.values
          .where((s) => s.allowedNext.contains(FormalRequestStatus.notSuccessful))
          .toList();
      expect(offering, [FormalRequestStatus.parentsVisited]);
    });

    test('calledOff is offered from both live stages', () {
      final offering = FormalRequestStatus.values
          .where((s) => s.allowedNext.contains(FormalRequestStatus.calledOff))
          .toList();
      expect(offering, [
        FormalRequestStatus.waitingForParentAppointment,
        FormalRequestStatus.parentsVisited,
      ]);
    });

    test('the three terminal states stay terminal', () {
      for (final terminal in [
        FormalRequestStatus.successfullyClosed,
        FormalRequestStatus.notSuccessful,
        FormalRequestStatus.calledOff,
        FormalRequestStatus.unknown,
      ]) {
        expect(terminal.allowedNext, isEmpty);
        expect(terminal.isTerminal, isTrue);
      }
    });
  });

  group('what the sheet offers', () {
    test('all four targets are listed, forward steps first', () {
      expect(statusUpdateTargets, [
        FormalRequestStatus.parentsVisited,
        FormalRequestStatus.successfullyClosed,
        FormalRequestStatus.notSuccessful,
        FormalRequestStatus.calledOff,
      ]);
    });

    test('every listed target is reachable from somewhere', () {
      final reachable = {
        for (final from in FormalRequestStatus.values) ...from.allowedNext,
      };
      expect(statusUpdateTargets.toSet(), reachable);
    });
  });

  group('labels', () {
    test('the closures carry their own verbs', () {
      expect(
        actionLabelKey(FormalRequestStatus.notSuccessful),
        LocaleKeys.matchmaker_cases_action_not_successful,
      );
      expect(
        actionLabelKey(FormalRequestStatus.calledOff),
        LocaleKeys.matchmaker_cases_action_close_case,
      );
    });

    test('the forward steps keep theirs', () {
      expect(
        actionLabelKey(FormalRequestStatus.parentsVisited),
        LocaleKeys.matchmaker_cases_action_parents_visited,
      );
      expect(
        actionLabelKey(FormalRequestStatus.successfullyClosed),
        LocaleKeys.matchmaker_cases_action_successfully_closed,
      );
    });

    test('every offered target has a label and an icon', () {
      for (final target in statusUpdateTargets) {
        expect(actionLabelKey(target), isNotEmpty, reason: target.name);
        expect(formalStatusIcon(target), isNotNull, reason: target.name);
      }
    });
  });

  group('wire round-trip', () {
    test('every sendable status parses back to itself', () {
      for (final status in FormalRequestStatus.values) {
        final wire = status.apiValue;
        if (wire == null) continue;
        expect(
          FormalRequestStatus.fromString(wire),
          status,
          reason: '$wire did not round-trip',
        );
      }
    });

    test('unknown is never sent', () {
      expect(FormalRequestStatus.unknown.apiValue, isNull);
    });
  });
}
