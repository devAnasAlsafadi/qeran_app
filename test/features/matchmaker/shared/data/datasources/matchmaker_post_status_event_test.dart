import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/domain/entities/community_post.dart';
import 'package:qeran/features/matchmaker/shared/data/datasources/matchmaker_realtime_signalr_service.dart';
import 'package:qeran/features/matchmaker/shared/domain/entities/community_post_status_change.dart';

/// `CommunityPostStatusChanged` (contract §6) on her realtime port.
void main() {
  late MatchmakerRealtimeSignalRService service;
  setUp(() {
    service = MatchmakerRealtimeSignalRService(
      accessTokenProvider: () async => 'token',
    );
  });
  tearDown(() => service.dispose());

  test('{ postId, status } reaches postStatusChanges', () async {
    final next = service.postStatusChanges.first;

    service.onPostStatusForTest([
      {'postId': 5, 'status': 'Published'},
    ]);

    expect(
      await next,
      const CommunityPostStatusChange(
        postId: 5,
        status: CommunityPostStatus.published,
      ),
    );
  });

  test('a failed post, and a status this build does not know', () async {
    final heard = <CommunityPostStatusChange>[];
    final sub = service.postStatusChanges.listen(heard.add);

    service.onPostStatusForTest([
      {'postId': '6', 'status': 'Failed'},
    ]);
    service.onPostStatusForTest([
      {'postId': 7, 'status': 'Archived'},
    ]);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(heard.map((c) => (c.postId, c.status)), [
      (6, CommunityPostStatus.failed),
      (7, CommunityPostStatus.unknown),
    ]);
  });

  test('no post id, or no payload, is dropped', () async {
    final heard = <CommunityPostStatusChange>[];
    final sub = service.postStatusChanges.listen(heard.add);

    service.onPostStatusForTest([
      {'status': 'Published'},
    ]);
    service.onPostStatusForTest(null);
    service.onPostStatusForTest(const ['not a map']);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(heard, isEmpty);
  });
}
