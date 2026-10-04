import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/report/domain/entities/report_reason.dart';
import 'package:qeran/features/report/presentation/blocs/report_cubit.dart';
import 'package:qeran/features/report/presentation/blocs/report_state.dart';
import 'package:qeran/generated/locale_keys.g.dart';

/// One report, sent through whatever call its target was given (Q3), and
/// its answer as one outcome.
void main() {
  final sent = <(ReportReason, String?)>[];
  late Either<Failure, void> answer;
  late ReportCubit cubit;

  setUp(() {
    sent.clear();
    answer = const Right(null);
    cubit = ReportCubit(
      send: (reason, note) async {
        sent.add((reason, note));
        return answer;
      },
    );
  });

  tearDown(() => cubit.close());

  Failure coded(String code) =>
      CodedServerFailure(message: 'x', errorCode: code);

  test('sends the reason and the note through its call', () async {
    await cubit.submit(reason: ReportReason.spam, note: 'رقم هاتف');

    expect(sent, [(ReportReason.spam, 'رقم هاتف')]);
    expect(cubit.state.outcome, ReportOutcome.success);
    expect(cubit.state.messageKey, LocaleKeys.report_success);
  });

  for (final (code, outcome, key) in [
    (
      'TARGET_CONTENT_NOT_FOUND',
      ReportOutcome.gone,
      LocaleKeys.report_content_gone,
    ),
    (
      'TARGET_USER_NOT_FOUND',
      ReportOutcome.failure,
      LocaleKeys.report_error_target_unavailable,
    ),
    (
      'VALIDATION_ERROR',
      ReportOutcome.failure,
      LocaleKeys.report_error_validation,
    ),
    ('ANYTHING_ELSE', ReportOutcome.failure, LocaleKeys.errors_generic),
  ]) {
    test('$code → $outcome', () async {
      answer = Left(coded(code));

      await cubit.submit(reason: ReportReason.other);

      expect(cubit.state.outcome, outcome);
      expect(cubit.state.messageKey, key);
      expect(cubit.state.submitting, isFalse);
    });
  }

  test('offline is a failure the member can retry', () async {
    answer = const Left(OfflineFailure());

    await cubit.submit(reason: ReportReason.other);

    expect(cubit.state.outcome, ReportOutcome.failure);
  });

  test('a second tap while sending sends nothing more', () async {
    final pending = Completer<Either<Failure, void>>();
    final slow = ReportCubit(
      send: (reason, note) {
        sent.add((reason, note));
        return pending.future;
      },
    );
    addTearDown(slow.close);

    final first = slow.submit(reason: ReportReason.spam);
    await slow.submit(reason: ReportReason.spam);
    pending.complete(const Right(null));
    await first;

    expect(sent, hasLength(1));
  });
}
