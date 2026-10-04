import 'package:qeran/core/services/connectivity_service.dart';

import 'community_mock_datasource.dart';
import 'community_mock_mode.dart';
import 'community_mock_records.dart';
import 'community_mock_seed.dart';
import 'community_mock_store.dart';

/// Who the dev-flag build answers as.
const communityMockDevViewer = CommunityMockViewer(
  id: 'mock-me',
  displayName: 'Dima Alsafadi',
);

/// The dev-flag build: 500 ms per call (3 s for [CommunityMockMode.slow]),
/// offline when the device is.
CommunityMockDataSource communityMockDevFlag(
  CommunityMockMode mode, {
  required ConnectivityService connectivity,
}) {
  DateTime now() => DateTime.now().toUtc();
  return CommunityMockDataSource(
    store: CommunityMockStore(
      viewer: communityMockDevViewer,
      now: now,
      seed: CommunityMockSeed.build(
        now(),
        viewer: communityMockDevViewer,
        empty: mode == CommunityMockMode.empty,
      ),
    ),
    latency: mode == CommunityMockMode.slow
        ? const Duration(seconds: 3)
        : const Duration(milliseconds: 500),
    connectivity: connectivity,
    failEverything: mode == CommunityMockMode.errors,
  );
}
