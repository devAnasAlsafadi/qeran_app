import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/data/media/video_compress_adapter.dart';

/// No fake on the channel: the plugin is missing, as on a platform it
/// doesn't build for. In its own file, because after a missing plugin the
/// package stays "compressing" for the rest of the isolate.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final adapter = VideoCompressAdapter(platform: TargetPlatform.android);

  test('inspect answers null', () async {
    expect(await adapter.inspect('/videos/a.mp4'), isNull);
  });

  test('compress answers null, and so does the next call, which the package '
      'refuses as already compressing', () async {
    expect(await adapter.compress('/videos/a.mp4'), isNull);
    expect(await adapter.compress('/videos/a.mp4'), isNull);
  });
}
