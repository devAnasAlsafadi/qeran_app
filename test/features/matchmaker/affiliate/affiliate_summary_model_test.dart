import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/affiliate/data/models/affiliate_summary_model.dart';
import 'package:qeran/features/matchmaker/affiliate/domain/entities/affiliate_commission_type.dart';

/// A full summary payload with overridable fields, so each test tweaks only the
/// keys it cares about.
Map<String, dynamic> _payload({
  Object? commissionRate = 10.0,
  Object? commissionType = 'percent',
}) =>
    {
      'referralCode': 'ABC123',
      'commissionRate': commissionRate,
      'commissionType': commissionType,
      'referredUsersCount': 5,
      'registeredUsersCount': 5,
      'codeUsedCount': 3,
      'totalCommission': 100,
      'pendingCommission': 40,
      'paidCommission': 60,
      'currency': 'USD',
    };

void main() {
  group('AffiliateSummaryModel.fromJson — commission rate/type', () {
    test('parses a percent rate', () {
      final m = AffiliateSummaryModel.fromJson(_payload());
      expect(m.commissionRate, 10.0);
      expect(m.commissionType, AffiliateCommissionType.percent);
    });

    test('parses a fixed rate (case-insensitive)', () {
      final m = AffiliateSummaryModel.fromJson(
        _payload(commissionRate: 12.5, commissionType: 'Fixed'),
      );
      expect(m.commissionRate, 12.5);
      expect(m.commissionType, AffiliateCommissionType.fixed);
    });

    test('null rate stays null (no fabrication)', () {
      final m = AffiliateSummaryModel.fromJson(
        _payload(commissionRate: null, commissionType: null),
      );
      expect(m.commissionRate, isNull);
      expect(m.commissionType, isNull);
    });

    test('unknown / empty commissionType resolves to null', () {
      expect(
        AffiliateSummaryModel.fromJson(_payload(commissionType: 'weekly'))
            .commissionType,
        isNull,
      );
      expect(
        AffiliateSummaryModel.fromJson(_payload(commissionType: ''))
            .commissionType,
        isNull,
      );
    });

    test('tolerates a rate sent as a numeric string', () {
      final m = AffiliateSummaryModel.fromJson(_payload(commissionRate: '10'));
      expect(m.commissionRate, 10.0);
    });

    test('toEntity carries rate + type through', () {
      final e = AffiliateSummaryModel.fromJson(_payload()).toEntity();
      expect(e.commissionRate, 10.0);
      expect(e.commissionType, AffiliateCommissionType.percent);
      expect(e.currency, 'USD');
      expect(e.registeredUsersCount, 5);
      expect(e.codeUsedCount, 3);
    });
  });
}
