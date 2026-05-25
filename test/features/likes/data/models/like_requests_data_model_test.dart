import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/likes/data/models/like_requests_data_model.dart';
import 'package:qeran/features/likes/domain/entities/like_request_status.dart';

void main() {
  group('LikeRequestsDataModel — parsing', () {
    test('subscribed incoming response — full card', () {
      final model = LikeRequestsDataModel.fromJson({
        'pending': [
          {
            'likeRequestId': 42,
            'profileId': 'guid-sender',
            'name': 'محمد',
            'profileImage': {
              'id': 'img-guid',
              'url': '/api/users/profile-images/img-guid',
              'isProfile': true,
              'isBlurred': true,
            },
            'status': 'Pending',
            'createdAt': '2026-05-17T10:30:00Z',
            'remainingSeconds': 172800,
            'actions': ['accept', 'reject'],
            'isLocked': false,
          },
        ],
        'archived': [],
        'requiresSubscription': false,
      });

      expect(model.requiresSubscription, false);
      expect(model.pending, hasLength(1));
      final card = model.pending.first;
      expect(card.likeRequestId, 42);
      expect(card.profileId, 'guid-sender');
      expect(card.name, 'محمد');
      expect(card.status, LikeRequestStatus.pending);
      expect(card.isLocked, false);
      expect(card.actions, ['accept', 'reject']);
      expect(card.remainingSeconds, 172800);
      expect(card.profileImage, isNotNull);
      expect(card.profileImage!.isBlurred, true);
      // The URL is resolved to absolute via EndPoints.absoluteUrl.
      expect(card.profileImage!.url, contains('/api/users/profile-images/'));
    });

    test('unsubscribed incoming response — locked + redacted', () {
      final model = LikeRequestsDataModel.fromJson({
        'pending': [
          {
            'likeRequestId': 42,
            'profileId': '',
            'name': '',
            'profileImage': null,
            'status': 'Pending',
            'remainingSeconds': 172800,
            'actions': [],
            'isLocked': true,
          },
        ],
        'archived': [],
        'requiresSubscription': true,
      });

      expect(model.requiresSubscription, true);
      final card = model.pending.first;
      expect(card.isLocked, true);
      expect(card.profileId, '');
      expect(card.name, '');
      expect(card.profileImage, isNull);
      expect(card.actions, isEmpty);
    });

    test('outgoing — archived statuses present', () {
      final model = LikeRequestsDataModel.fromJson({
        'pending': [],
        'archived': [
          {
            'likeRequestId': 1,
            'name': 'سارة',
            'status': 'Accepted',
            'actions': [],
            'isLocked': false,
          },
          {
            'likeRequestId': 2,
            'name': 'ليلى',
            'status': 'Rejected',
            'actions': [],
            'isLocked': false,
          },
          {
            'likeRequestId': 3,
            'name': 'هدى',
            'status': 'Expired',
            'actions': [],
            'isLocked': false,
          },
        ],
        'requiresSubscription': false,
      });

      expect(model.archived.map((e) => e.status).toList(), [
        LikeRequestStatus.accepted,
        LikeRequestStatus.rejected,
        LikeRequestStatus.expired,
      ]);
    });

    test('unknown status falls back to LikeRequestStatus.unknown', () {
      final model = LikeRequestsDataModel.fromJson({
        'pending': [
          {
            'likeRequestId': 99,
            'status': 'TotallyNewStatus',
            'isLocked': false,
            'actions': [],
          },
        ],
        'archived': [],
        'requiresSubscription': false,
      });

      expect(model.pending.first.status, LikeRequestStatus.unknown);
    });

    test(
        'numeric status — current backend shape maps 0..3 to '
        'Pending/Accepted/Rejected/Expired', () {
      final model = LikeRequestsDataModel.fromJson({
        'pending': [
          {'likeRequestId': 1, 'status': 0, 'actions': [], 'isLocked': false},
        ],
        'archived': [
          {'likeRequestId': 2, 'status': 1, 'actions': [], 'isLocked': false},
          {'likeRequestId': 3, 'status': 2, 'actions': [], 'isLocked': false},
          {'likeRequestId': 4, 'status': 3, 'actions': [], 'isLocked': false},
          {'likeRequestId': 5, 'status': 99, 'actions': [], 'isLocked': false},
        ],
        'requiresSubscription': false,
      });

      expect(model.pending.first.status, LikeRequestStatus.pending);
      expect(model.archived[0].status, LikeRequestStatus.accepted);
      expect(model.archived[1].status, LikeRequestStatus.rejected);
      expect(model.archived[2].status, LikeRequestStatus.expired);
      expect(model.archived[3].status, LikeRequestStatus.unknown);
    });

    test('envelope shape — status:1 wrapped data parses', () {
      // Simulate what the *current* backend returns; the data source
      // unwraps `data` before handing to `LikeRequestsDataModel.fromJson`.
      // We invoke the model directly here on the unwrapped slice so the
      // model layer's contract stays pure (the envelope check is unit-
      // tested at the data-source level in a separate file if needed).
      final envelope = {
        'status': 1,
        'data': {
          'pending': [
            {
              'likeRequestId': 13,
              'name': 'ola',
              'status': 0,
              'remainingSeconds': 172021,
              'actions': [],
              'isLocked': false,
            },
          ],
          'archived': [],
          'requiresSubscription': false,
        },
        'message': 'تم جلب الإعجابات الصادرة',
      };

      final inner = envelope['data'] as Map<String, dynamic>;
      final model = LikeRequestsDataModel.fromJson(inner);

      expect(model.pending.first.name, 'ola');
      expect(model.pending.first.status, LikeRequestStatus.pending);
      expect(model.pending.first.remainingSeconds, 172021);
    });

    test('real backend sample (no envelope, numeric status) parses', () {
      // Exact shape captured from the live `/api/likes/outgoing`.
      final model = LikeRequestsDataModel.fromJson({
        'pending': [
          {
            'likeRequestId': 13,
            'profileId': '58fa5041-141b-4147-a0a4-aa5159d09823',
            'name': 'ola',
            'profileImage': {
              'id': '49be63e3-f8b2-4d62-aaaa-d92417f96b57',
              'url':
                  '/api/users/profile-images/49be63e3-f8b2-4d62-aaaa-d92417f96b57',
              'isProfile': true,
              'isBlurred': true,
            },
            'status': 0,
            'remainingSeconds': 172021,
            'createdAt': '2026-05-20T10:58:35.3331605',
            'actions': [],
            'isLocked': false,
          },
        ],
        'archived': [],
        'requiresSubscription': false,
      });

      expect(model.requiresSubscription, false);
      expect(model.pending, hasLength(1));
      final card = model.pending.first;
      expect(card.likeRequestId, 13);
      expect(card.name, 'ola');
      expect(card.status, LikeRequestStatus.pending);
      expect(card.isLocked, false);
      expect(card.remainingSeconds, 172021);
      expect(card.profileImage, isNotNull);
      expect(card.profileImage!.isBlurred, true);
    });

    test('missing fields default safely — no crash', () {
      final model = LikeRequestsDataModel.fromJson({
        'pending': [
          // Only required fields per the wire; all others absent.
          {'likeRequestId': 7},
        ],
        'archived': [],
        // requiresSubscription deliberately omitted — must default to false.
      });

      expect(model.requiresSubscription, false);
      final card = model.pending.first;
      expect(card.likeRequestId, 7);
      expect(card.name, '');
      expect(card.profileId, '');
      expect(card.profileImage, isNull);
      expect(card.actions, isEmpty);
      expect(card.remainingSeconds, isNull);
      expect(card.status, LikeRequestStatus.unknown);
      expect(card.isLocked, false);
    });
  });
}
