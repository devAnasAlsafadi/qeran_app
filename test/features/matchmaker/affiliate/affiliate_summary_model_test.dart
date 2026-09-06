import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/matchmaker/affiliate/data/models/affiliate_summary_model.dart';
import 'package:qeran/features/matchmaker/affiliate/domain/entities/affiliate_code.dart';
import 'package:qeran/features/matchmaker/affiliate/domain/entities/affiliate_commission_type.dart';
import 'package:qeran/features/matchmaker/affiliate/domain/entities/affiliate_summary.dart';

/// A full summary payload with overridable fields, so each test tweaks only the
/// keys it cares about.
/// Distinguishes "the caller passed nothing" from "the caller passed null",
/// since both are real payload shapes with the same expected outcome.
const Object _absent = Object();

Map<String, dynamic> _payload({
  Object? commissionRate = 10.0,
  Object? commissionType = 'percent',
  Object? codes = _absent,
}) =>
    {
      if (!identical(codes, _absent)) 'codes': codes,
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

  group('AffiliateSummaryModel.fromJson — the codes list', () {
    // The account totals are the SUM across every code. Before this list the
    // dashboard named ONE code and showed those sums under it, so a second
    // code's earnings read as the first one's. What is asserted here is that
    // the per-code figures arrive intact and separable.
    List<Map<String, dynamic>> anosaCodes() => [
          {
            'code': 'ANAS',
            'isPrimary': true,
            'discountPercent': 10.0,
            'commissionRate': 10.0,
            'codeUsedCount': 1,
            'totalCommission': 3.68,
          },
          {
            'code': 'MQ',
            'isPrimary': false,
            'discountPercent': 50.0,
            'commissionRate': 10.0,
            'codeUsedCount': 2,
            'totalCommission': 6.59,
          },
        ];

    test('parses both codes, in order, keeping each figure its own', () {
      final e = AffiliateSummaryModel.fromJson(
        _payload(codes: anosaCodes()),
      ).toEntity();

      expect(e.codes.map((c) => c.code).toList(), ['ANAS', 'MQ']);
      expect(e.codes.first.isPrimary, isTrue);
      expect(e.codes.last.isPrimary, isFalse);
      expect(e.codes.last.codeUsedCount, 2);
      expect(e.codes.last.totalCommission, 6.59);
    });

    test('the buyer discount and the commission stay separate fields', () {
      final mq = AffiliateSummaryModel.fromJson(_payload(codes: anosaCodes()))
          .toEntity()
          .codes
          .last;

      // MQ takes 50% off the BUYER's price and earns the matchmaker 10%.
      // Collapsing these into one number overstates her income fivefold, so
      // they must not even share a field.
      expect(mq.discountPercent, 50.0);
      expect(mq.commissionRate, 10.0);
    });

    test('an absent, null or non-list value is an EMPTY list, never null', () {
      for (final raw in <Object?>[_absent, null, 'nonsense', 42]) {
        final e = raw == _absent
            ? AffiliateSummaryModel.fromJson(_payload()).toEntity()
            : AffiliateSummaryModel.fromJson(_payload(codes: raw)).toEntity();
        expect(e.codes, isEmpty, reason: 'codes was $raw');
      }
    });

    test('a malformed entry is skipped, its valid sibling survives', () {
      final e = AffiliateSummaryModel.fromJson(
        _payload(codes: ['not a map', anosaCodes().first]),
      ).toEntity();

      expect(e.codes, hasLength(1));
      expect(e.codes.single.code, 'ANAS');
    });

    test('the account totals are untouched by the list', () {
      final e = AffiliateSummaryModel.fromJson(
        _payload(codes: anosaCodes()),
      ).toEntity();

      expect(e.referralCode, 'ABC123');
      expect(e.codeUsedCount, 3);
      expect(e.totalCommission, 100);
      expect(e.pendingCommission, 40);
      expect(e.paidCommission, 60);
    });
  });

  group('reconciliation — a backend fault the device should announce', () {
    AffiliateSummary summaryWith({
      required List<AffiliateCode> codes,
      int codeUsedCount = 3,
      double totalCommission = 10.27,
    }) =>
        AffiliateSummary(
          referralCode: 'ANAS',
          codes: codes,
          commissionRate: 10,
          commissionType: AffiliateCommissionType.percent,
          referredUsersCount: 3,
          registeredUsersCount: 3,
          codeUsedCount: codeUsedCount,
          totalCommission: totalCommission,
          pendingCommission: 10.27,
          paidCommission: 0,
          currency: 'USD',
        );

    AffiliateCode code(String name, int used, double earned) => AffiliateCode(
          code: name,
          isPrimary: name == 'ANAS',
          discountPercent: 10,
          commissionRate: 10,
          codeUsedCount: used,
          totalCommission: earned,
        );

    test("the live payload reconciles", () {
      final s = summaryWith(
        codes: [code('ANAS', 1, 3.68), code('MQ', 2, 6.59)],
      );
      expect(s.codesUsedSum, 3);
      expect(s.codesReconcile, isTrue);
    });

    test('a sum that drifts in float still reconciles', () {
      // The tolerance exists for this, not for the numbers above — those add
      // up exactly, which is luck about those values. Under `==` this healthy
      // payload would be reported as drift, and a warning that fires on
      // correct data is one nobody reads.
      expect(0.1 + 0.2 == 0.3, isFalse,
          reason: 'precondition — if doubles ever add exactly, the tolerance '
              'has nothing left to prove and this test is vacuous');

      final s = summaryWith(
        codes: [code('ANAS', 1, 0.1), code('MQ', 2, 0.2)],
        totalCommission: 0.3,
      );
      expect(s.codesReconcile, isTrue);
    });

    test('a counter out of step with the rows is caught', () {
      final s = summaryWith(
        codes: [code('ANAS', 1, 3.68), code('MQ', 2, 6.59)],
        codeUsedCount: 4,
      );
      expect(s.codesReconcile, isFalse);
    });

    test('money out of step is caught', () {
      final s = summaryWith(
        codes: [code('ANAS', 1, 3.68), code('MQ', 2, 6.59)],
        totalCommission: 12.00,
      );
      expect(s.codesReconcile, isFalse);
    });

    test('an empty list is not a disagreement', () {
      // Also the pre-deploy payload: nothing to compare is not a fault, and
      // warning here would fire on every account with no list yet.
      expect(summaryWith(codes: const []).codesReconcile, isTrue);
    });
  });

}
