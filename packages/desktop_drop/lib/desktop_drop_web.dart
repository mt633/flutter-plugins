import 'dart:async';
import 'dart:html' as html show window, Url, FileReader, File;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'src/drop_item.dart';

/// A web implementation of the DesktopDrop plugin.
class DesktopDropWeb {
  final MethodChannel channel;
  final int _readStreamChunkSize = 300 * 1024; // 300 KB
  final List<html.File> _files = [];

  DesktopDropWeb._private(this.channel);

  static void registerWith(Registrar registrar) {
    final MethodChannel channel = MethodChannel(
      'desktop_drop',
      const StandardMethodCodec(),
      registrar,
    );

    final pluginInstance = DesktopDropWeb._private(channel);
    channel.setMethodCallHandler(pluginInstance.handleMethodCall);
    pluginInstance._registerEvents();
  }

  void _registerEvents() {
    html.window.onDrop.listen((event) async {
      event.preventDefault();

      final results = <WebDropItem>[];

      try {
        final items = event.dataTransfer.files;
        if (items != null) {
          _files.addAll(items);
          for (final item in items) {
            results.add(
              WebDropItem(
                uri: html.Url.createObjectUrl(item),
                name: item.name,
                size: item.size,
                type: item.type,
                relativePath: item.relativePath,
                lastModified: item.lastModified != null
                    ? DateTime.fromMillisecondsSinceEpoch(item.lastModified!)
                    : item.lastModifiedDate,
              ),
            );
          }
        }
      } catch (e, s) {
        debugPrint('desktop_drop_web: $e $s');
      } finally {
        channel.invokeMethod(
          "performOperation_web",
          results.map((e) => e.toJson()).toList(),
        );
      }
    });

    html.window.onDragEnter.listen((event) {
      event.preventDefault();
      channel.invokeMethod('entered', [
        event.client.x.toDouble(),
        event.client.y.toDouble(),
      ]);
    });

    html.window.onDragOver.listen((event) {
      event.preventDefault();
      channel.invokeMethod('updated', [
        event.client.x.toDouble(),
        event.client.y.toDouble(),
      ]);
    });

    html.window.onDragLeave.listen((event) {
      event.preventDefault();
      channel.invokeMethod('exited', [
        event.client.x.toDouble(),
        event.client.y.toDouble(),
      ]);
    });
  }

  Stream<List<int>> _openFileReadStream(html.File file) async* {
    final reader = html.FileReader();
    int start = 0;
    while (start < file.size) {
      final end = start + _readStreamChunkSize > file.size
          ? file.size
          : start + _readStreamChunkSize;
      final blob = file.slice(start, end);
      reader.readAsArrayBuffer(blob);
      await reader.onLoad.first;
      yield reader.result as List<int>;
      start += _readStreamChunkSize;
    }
  }

  Future<dynamic> handleMethodCall(MethodCall call) async {
    if (call.method == 'stream') {
      var file = _files.firstWhere(
        (element) => element.name == call.arguments,
        orElse: () => html.File([1], 'empty'),
      );
      if (file.name != 'empty') {
        _openFileReadStream(file).listen(
          (event) {
            channel.invokeMethod(
              "stream",
              [file.name, event],
            );
          },
          onDone: () {
            channel.invokeMethod(
              "stream",
              [file.name, []],
            );
            _files.remove(file);
          },
          onError: (e) {
            channel.invokeMethod(
              "stream",
              [file.name, null, e],
            );
            _files.remove(file);
          },
        );
      } else {
        channel.invokeMethod(
          "stream",
          [call.arguments, null, 'No such file!'],
        );
      }
      return;
    }
    throw PlatformException(
      code: 'Unimplemented',
      details: 'desktop_drop for web doesn\'t implement \'${call.method}\'',
    );
  }
}
