import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:qeran/core/api/api_consumer.dart';
import 'package:qeran/core/api/end_points.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:qeran/features/chat/data/error_codes.dart';
import 'package:qeran/features/chat/domain/entities/my_matchmaker_outcome.dart';
import 'package:qeran/features/chat/domain/entities/send_text_outcome.dart';
import 'package:qeran/features/chat/domain/entities/share_profile_outcome.dart';
import 'package:qeran/generated/locale_keys.g.dart';

class _MockApiConsumer extends Mock implements ApiConsumer {}

void main() {
  late _MockApiConsumer api;
  late ChatRemoteDataSourceImpl ds;

  setUp(() {
    api = _MockApiConsumer();
    ds = ChatRemoteDataSourceImpl(apiConsumer: api);
  });

  group('getMyMatchmaker', () {
    test('hits /api/chat/my-matchmaker via getRaw', () async {
      when(() => api.getRaw(any())).thenAnswer((_) async => {
            'status': 1,
            'message': '',
            'data': {
              'matchmakerId': 'mm',
              'name': 'أم محمد',
              'profileImageUrl': '/api/users/profile-images/mm',
              'conversationId': 42,
            },
          });

      final outcome = await ds.getMyMatchmaker();

      verify(() => api.getRaw(EndPoints.chatMyMatchmaker)).called(1);
      expect(outcome, isA<MyMatchmakerAssigned>());
      expect((outcome as MyMatchmakerAssigned).info.conversationId, 42);
    });

    test('status:0 with no errorCode → MyMatchmakerNotAssigned', () async {
      when(() => api.getRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'message': 'لم يتم تعيين خطّابة لك بعد',
            'data': null,
          });

      final outcome = await ds.getMyMatchmaker();
      expect(outcome, isA<MyMatchmakerNotAssigned>());
    });

    // Backend batch 22: all three documented failures on this endpoint come
    // with no errorCode, and the realistic one is a product state. A code
    // arriving anyway is logged as unhandled but must not change what the
    // member sees — guessing at a response would be worse than the calm card.
    test('an unhandled code in a 200 envelope still reads as not-assigned', () async {
      when(() => api.getRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'message': 'something went wrong',
            'errorCode': 'SOME_SERVER_CODE',
            'data': null,
          });

      final outcome = await ds.getMyMatchmaker();
      expect(outcome, isA<MyMatchmakerNotAssigned>());
    });

    test('an empty errorCode changes nothing either', () async {
      when(() => api.getRaw(any())).thenAnswer((_) async => {
            'status': 0,
            'message': 'لم يتم تعيين خطّابة لك بعد',
            'errorCode': '',
            'data': null,
          });

      final outcome = await ds.getMyMatchmaker();
      expect(outcome, isA<MyMatchmakerNotAssigned>());
    });

    // A non-2xx is a different path entirely: getRaw throws, and the catch
    // below preserves the code on MyMatchmakerFailure. That half was never
    // swallowed and stays covered by the transport test above.
    test('a coded transport failure keeps its code', () async {
      when(() => api.getRaw(any())).thenThrow(
        CodedServerException(message: 'nope', errorCode: 'A_REAL_CODE'),
      );

      final outcome = await ds.getMyMatchmaker();

      expect(outcome, isA<MyMatchmakerFailure>());
      expect((outcome as MyMatchmakerFailure).errorCode, 'A_REAL_CODE');
    });
  });

  group('getMessages', () {
    test('hits /messages with paging params', () async {
      when(() => api.getRaw(any(),
              queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => {
                'status': 1,
                'message': '',
                'data': {
                  'data': const <Map<String, dynamic>>[],
                  'totalCount': 0,
                  'pageNumber': 1,
                  'pageSize': 30,
                  'totalPages': 0,
                },
              });

      await ds.getMessages(conversationId: 42, page: 1, pageSize: 30);

      final captured = verify(() => api.getRaw(
            captureAny(),
            queryParameters: captureAny(named: 'queryParameters'),
          )).captured;
      expect(captured.first, EndPoints.chatMessages(42));
      final qp = captured.last as Map<String, dynamic>;
      expect(qp['page'], 1);
      expect(qp['pageSize'], 30);
    });
  });

  group('sendTextMessage — typed outcomes', () {
    test('hits POST /messages with content body', () async {
      when(() => api.postRaw(any(), body: any(named: 'body')))
          .thenAnswer((_) async => {
                'status': 1,
                'message': 'تم إرسال الرسالة',
                'data': {
                  'id': 106,
                  'conversationId': 42,
                  'senderId': 'me',
                  'senderName': 'me',
                  'content': 'hello',
                  'sharedProfile': null,
                  'isRead': false,
                  'sentAt': '2026-05-17T15:00:00Z',
                },
              });

      final outcome = await ds.sendTextMessage(
        conversationId: 42,
        content: 'hello',
      );

      final captured = verify(() => api.postRaw(
            captureAny(),
            body: captureAny(named: 'body'),
          )).captured;
      expect(captured.first, EndPoints.chatSendMessage(42));
      expect((captured.last as Map)['content'], 'hello');
      expect(outcome, isA<SendTextSuccess>());
      expect((outcome as SendTextSuccess).message.serverId, 106);
    });

    test('VALIDATION_ERROR → SendTextValidationError', () async {
      when(() => api.postRaw(any(), body: any(named: 'body')))
          .thenAnswer((_) async => {
                'status': 0,
                'message': 'نص الرسالة مطلوب',
                'errorCode': ChatErrorCodes.validationError,
                'data': null,
              });
      final outcome = await ds.sendTextMessage(conversationId: 1, content: '');
      expect(outcome, isA<SendTextValidationError>());
    });

    test('CONVERSATION_NOT_FOUND → SendTextConversationNotFound', () async {
      when(() => api.postRaw(any(), body: any(named: 'body')))
          .thenAnswer((_) async => {
                'status': 0,
                'message': 'المحادثة غير موجودة',
                'errorCode': ChatErrorCodes.conversationNotFound,
                'data': null,
              });
      final outcome = await ds.sendTextMessage(conversationId: 1, content: 'a');
      expect(outcome, isA<SendTextConversationNotFound>());
    });

    test('UNAUTHORIZED → SendTextUnauthorized', () async {
      when(() => api.postRaw(any(), body: any(named: 'body')))
          .thenAnswer((_) async => {
                'status': 0,
                'message': 'ليست لديك صلاحية',
                'errorCode': ChatErrorCodes.unauthorized,
                'data': null,
              });
      final outcome = await ds.sendTextMessage(conversationId: 1, content: 'a');
      expect(outcome, isA<SendTextUnauthorized>());
    });

    test('HTTP 429 → SendTextRateLimited (mapped via too_many_requests key)',
        () async {
      // HttpConsumer surfaces 429 as ServerException(LocaleKeys.errors_too_many_requests).
      when(() => api.postRaw(any(), body: any(named: 'body'))).thenThrow(
        ServerException(message: LocaleKeys.errors_too_many_requests),
      );
      final outcome = await ds.sendTextMessage(conversationId: 1, content: 'a');
      expect(outcome, isA<SendTextRateLimited>());
    });

    test('unmapped CodedServerException → rethrows (repo turns into Left)',
        () async {
      when(() => api.postRaw(any(), body: any(named: 'body'))).thenThrow(
        CodedServerException(message: 'oops', errorCode: 'UNKNOWN'),
      );
      expect(
        () => ds.sendTextMessage(conversationId: 1, content: 'a'),
        throwsA(isA<ServerException>()),
      );
    });
  });

  group('shareProfile — typed outcomes', () {
    test('happy path returns ShareProfileSuccess with the shared profile',
        () async {
      when(() => api.postRaw(any(), body: any(named: 'body')))
          .thenAnswer((_) async => {
                'status': 1,
                'message': 'تم مشاركة البروفايل',
                'data': {
                  'id': 107,
                  'conversationId': 42,
                  'senderId': 'me',
                  'senderName': 'me',
                  'content': '[profile:y]',
                  'sharedProfile': {
                    'id': 'y',
                    'name': 'نور',
                    'age': 27,
                    'matchingScore': 78.5,
                    'images': const <Map<String, dynamic>>[],
                    'placements': const <Map<String, dynamic>>[],
                  },
                  'isRead': false,
                  'sentAt': '2026-05-17T15:00:00Z',
                },
              });
      final outcome = await ds.shareProfile(
        conversationId: 42,
        sharedUserId: 'y',
      );
      expect(outcome, isA<ShareProfileSuccess>());
      final msg = (outcome as ShareProfileSuccess).message;
      expect(msg.isSharedProfile, isTrue);
      expect(msg.sharedProfile!.name, 'نور');
    });

    test('PROFILE_NOT_FOUND → ShareProfileNotFound', () async {
      when(() => api.postRaw(any(), body: any(named: 'body')))
          .thenAnswer((_) async => {
                'status': 0,
                'message': 'البروفايل المُشارَك غير موجود',
                'errorCode': ChatErrorCodes.profileNotFound,
                'data': null,
              });
      final outcome = await ds.shareProfile(
        conversationId: 1,
        sharedUserId: 'x',
      );
      expect(outcome, isA<ShareProfileNotFound>());
    });

    test('VALIDATION_ERROR → ShareProfileValidationError', () async {
      when(() => api.postRaw(any(), body: any(named: 'body')))
          .thenAnswer((_) async => {
                'status': 0,
                'message': 'معرّف البروفايل مطلوب',
                'errorCode': ChatErrorCodes.validationError,
                'data': null,
              });
      final outcome = await ds.shareProfile(
        conversationId: 1,
        sharedUserId: '',
      );
      expect(outcome, isA<ShareProfileValidationError>());
    });

    test('HTTP 429 → ShareProfileRateLimited', () async {
      when(() => api.postRaw(any(), body: any(named: 'body'))).thenThrow(
        ServerException(message: LocaleKeys.errors_too_many_requests),
      );
      final outcome =
          await ds.shareProfile(conversationId: 1, sharedUserId: 'x');
      expect(outcome, isA<ShareProfileRateLimited>());
    });
  });

  group('markAsRead', () {
    test('hits POST /read', () async {
      when(() => api.postRaw(any())).thenAnswer((_) async => {
            'status': 1,
            'message': 'تم تحديد الرسائل كمقروءة',
            'data': null,
          });
      await ds.markAsRead(42);
      verify(() => api.postRaw(EndPoints.chatMarkAsRead(42))).called(1);
    });
  });
}
