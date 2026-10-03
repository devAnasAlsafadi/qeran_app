/// A video's length as a player writes it, in every language: `m:ss`
/// ("0:52", "1:30"), and `h:mm:ss` from an hour up.
String formatVideoDuration(Duration duration) {
  final total = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final seconds = (total % 60).toString().padLeft(2, '0');
  final minutes = total ~/ 60 % 60;
  final hours = total ~/ 3600;
  if (hours == 0) return '$minutes:$seconds';
  return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
}
