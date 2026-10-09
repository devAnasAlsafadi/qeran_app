import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/subscriptions/domain/entities/validate_code_response.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_state.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'package_purchase_code_rig.dart';

/// The discount field's error text is handed to `.t()` at the display site, so
/// whatever this cubit puts in it is treated as a locale KEY. Server prose
/// reaching there is printed verbatim — which read correctly in Arabic purely
/// because the backend happens to write Arabic, and would have shown Arabic to
/// an English member.
///
/// So the assertions below are about ORIGIN, not wording: the prose must not
/// survive into the state at all. And the two failures must stay distinct —
/// on a payment path, telling someone their code is wrong when the request
/// never completed is a lie they act on.

void main() {
  test('a rejected code never carries the server sentence', () async {
    final cubit = cubitFor(Right(rejected(message: serverProse)));

    final state = await validate(cubit);

    expect(state, isA<PackagePurchaseCodeValidationFailure>());
    final failure = state as PackagePurchaseCodeValidationFailure;
    expect(
      failure.message,
      LocaleKeys.subscriptions_discount_code_invalid,
      reason:
          'the display site calls .t() on this — prose here is printed '
          'raw, and an English member would be shown Arabic',
    );
    expect(failure.message, isNot(contains(serverProse)));
    await cubit.close();
  });

  test('a rejected code with NO message reads the same', () async {
    // The shape a malformed request now takes: 200 + status:0 parses to
    // valid:false with nothing to say. It must not degrade into the generic
    // error — the code WAS rejected, and that is what to tell the member.
    final cubit = cubitFor(Right(rejected()));

    final state = await validate(cubit);

    expect(
      (state as PackagePurchaseCodeValidationFailure).message,
      LocaleKeys.subscriptions_discount_code_invalid,
      reason:
          'asserting the EXACT key, not merely that it looks like one: '
          'errors.generic is also a valid key and would pass that weaker test',
    );
    await cubit.close();
  });

  test('a request that failed does not blame the code', () async {
    final cubit = cubitFor(const Left(ServerFailure(message: serverProse)));

    final state = await validate(cubit);

    final failure = state as PackagePurchaseCodeValidationFailure;
    expect(failure.message, isNot(contains(serverProse)));
    expect(
      failure.message,
      LocaleKeys.errors_generic,
      reason:
          'the request never got an answer — saying the code is invalid '
          'would be a lie the member acts on at checkout',
    );
    await cubit.close();
  });

  test('a valid code still applies', () async {
    final cubit = cubitFor(
      const Right(
        ValidateCodeResponse(
          valid: true,
          discountPercent: 50,
          offerId: 'offer-mq',
          signature: null,
          keyId: null,
          nonce: null,
          timestampMs: null,
          message: null,
        ),
      ),
    );

    final state = await validate(cubit);

    expect(state, isA<PackagePurchaseCodeValidationSuccess>());
    expect(
      (state as PackagePurchaseCodeValidationSuccess).response.discountPercent,
      50,
    );
    await cubit.close();
  });
}
