/// The tallest frame a post's media gets: 4:5.
const double kTallestMediaAspect = 4 / 5;

/// The widest frame a post's media gets, and the frame for media of unknown
/// size: 16:9.
const double kWidestMediaAspect = 16 / 9;

/// The frame ratio (width / height) for media of [width] × [height] (A4, Q4):
/// its own ratio, clamped between 4:5 and 16:9 — one rule for a single image
/// and a video, in the card and on the post screen. No usable size (the
/// server sent none) → 16:9.
double clampedAspect(int width, int height) {
  if (width <= 0 || height <= 0) return kWidestMediaAspect;
  return (width / height).clamp(kTallestMediaAspect, kWidestMediaAspect);
}

/// The dots a carousel of [total] pages shows, at most [max] (S2): a window
/// that slides with [index] (zero-based), so the current page always has a
/// dot. The counter pill carries the exact position.
({int start, int count}) dotWindow(int total, int index, {int max = 6}) {
  if (total <= max) return (start: 0, count: total);
  final start = (index - max ~/ 2).clamp(0, total - max);
  return (start: start, count: max);
}
