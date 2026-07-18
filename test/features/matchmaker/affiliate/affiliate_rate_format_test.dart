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
}
