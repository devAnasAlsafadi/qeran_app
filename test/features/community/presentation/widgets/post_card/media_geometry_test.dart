import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/features/community/presentation/formatting/video_duration.dart';
import 'package:qeran/features/community/presentation/widgets/post_card/media_geometry.dart';

void main() {
  group('clampedAspect: its own ratio, between 4:5 and 16:9 (A4, Q4)', () {
    const cases = {
      (1080, 1920): 0.8, // a vertical reel: 9:16 → 4:5
      (900, 1600): 0.8,
      (1080, 1350): 0.8, // 4:5 exactly
      (1080, 1080): 1.0,
      (1200, 900): 4 / 3,
      (1920, 1080): 16 / 9,
      (2560, 1080): 16 / 9, // 21:9 → 16:9
      (0, 0): 16 / 9, // no size
      (1080, 0): 16 / 9,
    };
    for (final MapEntry(key: (w, h), value: ratio) in cases.entries) {
      test('$w × $h → $ratio', () {
        expect(clampedAspect(w, h), closeTo(ratio, 1e-9));
      });
    }
  });

  group('dotWindow: at most six, sliding with the page (S2)', () {
    test('six or fewer: every page has a dot', () {
      expect(dotWindow(3, 2), (start: 0, count: 3));
      expect(dotWindow(6, 5), (start: 0, count: 6));
    });

    test('eight: the window follows the page and stops at the ends', () {
      expect(dotWindow(8, 0), (start: 0, count: 6));
      expect(dotWindow(8, 3), (start: 0, count: 6));
      expect(dotWindow(8, 4), (start: 1, count: 6));
      expect(dotWindow(8, 7), (start: 2, count: 6));
    });

    test('the current page always has a dot', () {
      for (var i = 0; i < 20; i++) {
        final w = dotWindow(20, i);
        expect(i, inInclusiveRange(w.start, w.start + w.count - 1));
      }
    });
  });

  test('formatVideoDuration: m:ss, h:mm:ss from an hour', () {
    String f(int s) => formatVideoDuration(Duration(seconds: s));
    expect(
      [f(0), f(52), f(60), f(90), f(599)],
      ['0:00', '0:52', '1:00', '1:30', '9:59'],
    );
    expect(f(3605), '1:00:05');
    expect(f(-3), '0:00');
  });
}
