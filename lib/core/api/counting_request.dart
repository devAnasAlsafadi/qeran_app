import 'package:http/http.dart' as http;

/// A request whose body is counted as the client reads it, so progress
/// follows what the connection has taken rather than what was queued, and
/// which stops when [abortTrigger] completes. Our uploads and tus use it.
final class CountingRequest extends http.BaseRequest with http.Abortable {
  CountingRequest(
    super.method,
    super.url, {
    required Stream<List<int>> body,
    required int length,
    this.abortTrigger,
    this.onSent,
  }) : _body = body {
    contentLength = length;
  }

  final Stream<List<int>> _body;

  @override
  final Future<void>? abortTrigger;

  /// Bytes taken so far, after each chunk.
  final void Function(int sent)? onSent;

  @override
  http.ByteStream finalize() {
    super.finalize();
    var sent = 0;
    return http.ByteStream(
      _body.map((chunk) {
        sent += chunk.length;
        onSent?.call(sent);
        return chunk;
      }),
    );
  }
}
