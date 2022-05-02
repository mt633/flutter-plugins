import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class CustomPlatformFile extends PlatformFile {
  static const MethodChannel _channel = MethodChannel('desktop_drop');
  DateTime? lastModified;
  String? mimeType;
  StreamController<List<int>> streamController = StreamController();
  final Stream<List<int>>? _readStream;
  CustomPlatformFile({
    required String name,
    required int size,
    Uint8List? bytes,
    String? path,
    this.lastModified,
    this.mimeType,
    Stream<List<int>>? readStream,
  })  : _readStream = readStream,
        super(name: name, size: size, bytes: bytes, path: path);

  void stream(var data, var error) {
    if (data is List<int>) {
      streamController.sink.add(data);
    } else {
      if (data == null) {
        streamController.addError(error);
      }
      streamController.close();
    }
  }

  @override
  Stream<List<int>>? get readStream {
    if (_readStream == null) {
      _channel.invokeMethod(
        "stream",
        name,
      );
      return streamController.stream;
    } else {
      return _readStream;
    }
  }
}
