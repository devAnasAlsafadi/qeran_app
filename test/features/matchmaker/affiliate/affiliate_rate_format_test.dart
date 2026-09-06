import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/affiliate/domain/entities/affiliate_commission_type.dart';
import 'package:qeran/features/matchmaker/affiliate/presentation/widgets/affiliate_rate_format.dart';

void main() {
  group('formatCommissionRate', () {
    test('null rate → null (widget shows a neutral —)', () {
      expect(
        formatCommissionRate(null, AffiliateCommissionType.percent, 'USD'),
        isNull,
      );
    });

    test('percent → appends %', () {
      expect(
        formatCommissionRate(10, AffiliateCommissionType.percent, 'USD'),
        '10%',
      );
    });

    test('fixed → appends the currency, never %', () {
      final out = formatCommissionRate(10, AffiliateCommissionType.fixed, 'USD');
      expect(out, '10 USD');
      expect(out, isNot(contains('%')));
    });

    test('unknown/null type but a rate present → bare number (forward-safe)', () {
      expect(formatCommissionRate(10, null, 'USD'), '10');
    });

    test('whole numbers drop decimals; fractional show two places', () {
      expect(
        formatCommissionRate(10.0, AffiliateCommissionType.percent, 'USD'),
        '10%',
      );
      expect(
        formatCommissionRate(12.5, AffiliateCommissionType.percent, 'USD'),
        '12.50%',
      );
    });
  });

  group('formatPerCodeRate — silent unless it differs', () {
    test('equal to the account rate says nothing', () {
      expect(
        formatPerCodeRate(10, 10, AffiliateCommissionType.percent, 'USD'),
        isNull,
      );
    });

    test('an override is stated', () {
      expect(
        formatPerCodeRate(15, 10, AffiliateCommissionType.percent, 'USD'),
        '15%',
      );
    });

    test('no account rate to compare against says nothing', () {
      // "Differs" is not a claim that can be made against an unknown, and a
      // bare rate on one row would read as the headline it is not.
      expect(
        formatPerCodeRate(15, null, AffiliateCommissionType.percent, 'USD'),
        isNull,
      );
    });
  });

}
