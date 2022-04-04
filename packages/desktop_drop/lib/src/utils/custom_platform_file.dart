import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class CustomPlatformFile extends PlatformFile {
  static const MethodChannel _channel = MethodChannel('desktop_drop');
  DateTime? lastModified;
  String? mimeType;
  StreamController<List<int>> streamController = StreamController();
  CustomPlatformFile(
      {required String name,
      required int size,
      Uint8List? bytes,
      required String path,
      this.lastModified,
      this.mimeType})
      : super(name: name, size: size, bytes: bytes, path: path);

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
    _channel.invokeMethod(
      "stream",
      name,
    );
    return streamController.stream;
  }
}