import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/errors.dart';
import 'package:qeran/features/subscriptions/data/error_codes.dart';
import 'package:qeran/features/subscriptions/data/models/validate_code_response_model.dart';
import 'package:qeran/features/subscriptions/domain/entities/validate_code_response.dart';
import 'package:qeran/features/subscriptions/presentation/blocs/purchase/package_purchase_state.dart';
import 'package:qeran/generated/locale_keys.g.dart';

import 'package_purchase_code_rig.dart';

/// B3 (`03` §12.5): each refusal says which it was. The codes can arrive in a
/// `valid: false` answer, or as a failed request (a `success: false` body or
/// a non-2xx — both a `CodedServerFailure` by the time the cubit sees them),
/// so every code is checked both ways.
void main() {
  const expected = {
    SubscriptionsErrorCodes.discountCodeInvalid:
        LocaleKeys.subscriptions_discount_code_wrong,
    SubscriptionsErrorCodes.discountCodeExpired:
        LocaleKeys.subscriptions_discount_code_expired,
    SubscriptionsErrorCodes.discountCodeExhausted:
        LocaleKeys.subscriptions_discount_code_used_up,
    SubscriptionsErrorCodes.discountProductUnknown:
        LocaleKeys.subscriptions_discount_code_unavailable,
    SubscriptionsErrorCodes.discountOfferUnavailable:
        LocaleKeys.subscriptions_discount_code_unavailable,
  };

  Future<String> messageFor(
    Either<Failure, ValidateCodeResponse> answer,
  ) async {
    final cubit = cubitFor(answer);
    final state = await validate(cubit);
    await cubit.close();
    return (state as PackagePurchaseCodeValidationFailure).message;
  }

  for (final MapEntry(key: code, value: key) in expected.entries) {
    test('$code in a valid:false answer', () async {
      expect(await messageFor(Right(rejected(errorCode: code))), key);
    });

    test('$code as a failed request', () async {
      expect(
        await messageFor(
          Left(
            CodedServerFailure(
              message: serverProse,
              errorCode: code,
              statusCode: 400,
            ),
          ),
        ),
        key,
      );
    });
  }

  test('VALIDATION_ERROR is the generic error, not a verdict', () async {
    expect(
      await messageFor(
        const Left(
          CodedServerFailure(message: 'x', errorCode: 'VALIDATION_ERROR'),
        ),
      ),
      LocaleKeys.errors_generic,
    );
  });

  test('a valid:false with an unknown code keeps the old line', () async {
    expect(
      await messageFor(Right(rejected(errorCode: 'SOMETHING_NEW'))),
      LocaleKeys.subscriptions_discount_code_invalid,
    );
  });

  test('the model reads the code off the body', () {
    final model = ValidateCodeResponseModel.fromJson(const {
      'valid': false,
      'discountPercent': 0,
      'errorCode': 'DISCOUNT_CODE_EXPIRED',
    });

    expect(model.toEntity().errorCode, 'DISCOUNT_CODE_EXPIRED');
  });
}
