import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/errors/exceptions.dart';
import 'package:qeran/core/services/connectivity_service.dart';
import 'package:qeran/features/community/data/datasources/mock/community_mock_datasource.dart';
import 'package:qeran/features/community/data/datasources/mock/community_mock_dev_flag.dart';
import 'package:qeran/features/community/data/datasources/mock/community_mock_records.dart';
import 'package:qeran/features/community/data/datasources/mock/community_mock_seed.dart';
import 'package:qeran/features/community/data/datasources/mock/community_mock_store.dart';

/// A controllable clock for the mock: tests move [now] forward by hand.
class TestClock {
  DateTime now = DateTime.utc(2026, 10, 1, 12);

  void advance(Duration by) => now = now.add(by);
}

class FakeConnectivity implements ConnectivityService {
  bool online = true;

  @override
  Future<bool> get isOnline async => online;

  @override
  Stream<bool> get onStatusChange => const Stream.empty();
}

const me = communityMockDevViewer;

/// The seeded mock with no latency, as the tests' fake.
CommunityMockDataSource seededMock({
  TestClock? clock,
  CommunityMockViewer viewer = me,
  bool accepted = true,
  bool empty = false,
  ConnectivityService? connectivity,
  bool failEverything = false,
}) {
  final c = clock ?? TestClock();
  return CommunityMockDataSource(
    store: CommunityMockStore(
      viewer: viewer,
      now: () => c.now,
      seed: CommunityMockSeed.build(c.now, viewer: viewer, empty: empty),
    ),
    guidelinesAccepted: accepted,
    connectivity: connectivity,
    failEverything: failEverything,
  );
}

/// Matches what `HttpConsumer` throws for an enveloped error with [code].
Matcher throwsCoded(String code) => throwsA(
      isA<CodedServerException>().having((e) => e.errorCode, 'errorCode', code),
    );
