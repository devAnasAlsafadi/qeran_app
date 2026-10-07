import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// `video_compress`'s channel with the phone's side scripted, so the real
/// package runs between the adapter and this fake.
class VideoChannelRig {
  static const _channel = MethodChannel('video_compress');

  TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late Directory _dir;
  Completer<String?>? _compressing;

  /// Every call the package made, in order.
  final calls = <MethodCall>[];

  /// What `getMediaInfo` answers, by path. Any other path fails as an
  /// unreadable file fails on Android: the plugin throws, and the channel
  /// answers an error.
  final infos = <String, Map<String, Object?>>{};

  /// What the phone does on `cancelCompression`. By default nothing yet:
  /// it takes a moment to stop.
  void Function()? onCancel;

  Future<void> setUp() async {
    calls.clear();
    infos.clear();
    onCancel = null;
    _dir = await Directory.systemTemp.createTemp('video_compress');
    _messenger.setMockMethodCallHandler(_channel, _answer);
  }

  Future<void> tearDown() async {
    _messenger.setMockMethodCallHandler(_channel, null);
    await _dir.delete(recursive: true);
  }

  List<String> get methods => [for (final call in calls) call.method];

  List<MethodCall> get compressions => [
    for (final call in calls)
      if (call.method == 'compressVideo') call,
  ];

  /// A file of [bytes] bytes.
  String file(String name, int bytes) {
    final file = File('${_dir.path}/$name');
    file.writeAsBytesSync(List.filled(bytes, 0));
    return file.path;
  }

  /// The phone reports [percent] done: a number on Android, a string on
  /// iOS.
  Future<void> tick(Object percent) => _messenger.handlePlatformMessage(
    _channel.name,
    _channel.codec.encodeMethodCall(MethodCall('updateProgress', percent)),
    (_) {},
  );

  /// The phone answers the running compression with [json]. Null is
  /// Android's answer to a failure and to a cancel.
  void finish(Map<String, Object?>? json) =>
      _compressing!.complete(json == null ? null : jsonEncode(json));

  Future<Object?> _answer(MethodCall call) async {
    calls.add(call);
    switch (call.method) {
      case 'getMediaInfo':
        final info = infos[(call.arguments as Map)['path']];
        if (info == null) throw PlatformException(code: 'video_compress');
        return jsonEncode(info);
      case 'compressVideo':
        return (_compressing = Completer()).future;
      case 'cancelCompression':
        onCancel?.call();
    }
    return null;
  }
}

/// `getMediaInfo`'s JSON as the plugins write it.
Map<String, Object?> mediaJson(
  String path, {
  required int width,
  required int height,
  int? orientation,
  num duration = 30000,
  bool? isCancel,
}) => {
  'path': path,
  'title': '',
  'author': '',
  'width': width,
  'height': height,
  'duration': duration,
  'filesize': 1,
  'orientation': ?orientation,
  'isCancel': ?isCancel,
};
