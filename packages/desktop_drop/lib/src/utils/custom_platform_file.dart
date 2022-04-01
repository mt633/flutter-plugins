import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomPlatformFile extends PlatformFile {
  static const MethodChannel _channel = MethodChannel('desktop_drop');
  DateTime? lastModified;
  String? mimeType;
  Function(List<int>)? onStream;
  CustomPlatformFile(
      {required String name,
      required int size,
      Uint8List? bytes,
      required String path,
      this.lastModified,
      this.mimeType})
      : super(name: name, size: size, bytes: bytes, path: path) {
    _channel.setMethodCallHandler((call) async {
      try {
        switch (call.method) {
          case 'stream':
            if (onStream != null && call.arguments[0] == name) {
              onStream!(call.arguments[1]);
            }
            break;
        }
      } catch (e, s) {
        debugPrint('_handleMethodChannel: $e $s');
      }
    });
  }

  stream(Function(List<int> chunk) onStream) {
    this.onStream = onStream;
    _channel.invokeMethod(
      "stream",
      name,
    );
  }
}
