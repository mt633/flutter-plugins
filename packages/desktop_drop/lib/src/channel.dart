import 'dart:convert';

import 'package:desktop_drop/src/utils/custom_platform_file.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'drop_item.dart';
import 'events.dart';
import 'utils/platform.dart' if (dart.library.html) 'utils/platform_web.dart';

typedef RawDropListener = void Function(DropEvent);

class DesktopDrop {
  static const MethodChannel _channel = MethodChannel('desktop_drop');

  DesktopDrop._();

  static final instance = DesktopDrop._();

  final _listeners = <RawDropListener>{};

  var _inited = false;

  Offset? _offset;
  List<CustomPlatformFile>? results;

  void init() {
    if (_inited) {
      return;
    }
    _inited = true;
    _channel.setMethodCallHandler((call) async {
      try {
        return await _handleMethodChannel(call);
      } catch (e, s) {
        debugPrint('_handleMethodChannel: $e $s');
      }
    });
  }

  Future<void> _handleMethodChannel(MethodCall call) async {
    switch (call.method) {
      case "entered":
        if (_offset == null) {
          final position = (call.arguments as List).cast<double>();
          _offset = Offset(position[0], position[1]);
          _notifyEvent(DropEnterEvent(location: _offset!));
        }
        break;
      case "updated":
        if (_offset == null && Platform.isLinux) {
          final position = (call.arguments as List).cast<double>();
          _offset = Offset(position[0], position[1]);
          _notifyEvent(DropEnterEvent(location: _offset!));
          return;
        }
        if (_offset != null) {
          final position = (call.arguments as List).cast<double>();
          _offset = Offset(position[0], position[1]);
          _notifyEvent(DropUpdateEvent(location: _offset!));
        }
        break;
      case "exited":
        if (_offset != null) {
          _notifyEvent(DropExitEvent(location: _offset ?? Offset.zero));
          _offset = null;
        }
        break;
      case "performOperation":
        if (_offset != null) {
          final paths = (call.arguments as List).cast<String>();
          results = paths
              .map((e) => CustomPlatformFile(name: e, path: e, size: 0))
              .toList();
          _notifyEvent(
            DropDoneEvent(
              location: _offset ?? Offset.zero,
              files: results!,
            ),
          );
          _offset = null;
        }
        break;
      case "performOperation_linux":
        // gtk notify 'exit' before 'performOperation'.
        if (_offset == null) {
          final text = (call.arguments as List<dynamic>)[0] as String;
          final offset = ((call.arguments as List<dynamic>)[1] as List<dynamic>)
              .cast<double>();
          final paths = const LineSplitter().convert(text).map((e) {
            try {
              return Uri.tryParse(e)?.toFilePath() ?? '';
            } catch (error, stacktrace) {
              debugPrint('failed to parse linux path: $error $stacktrace');
            }
            return '';
          }).where((e) => e.isNotEmpty);
          results = paths
              .map((e) => CustomPlatformFile(name: e, path: e, size: 0))
              .toList();
          _notifyEvent(DropDoneEvent(
            location: Offset(offset[0], offset[1]),
            files: results!,
          ));
        }
        break;
      case "performOperation_web":
        if (_offset != null) {
          results = (call.arguments as List)
              .cast<Map>()
              .map((e) => WebDropItem.fromJson(e.cast<String, dynamic>()))
              .map((e) => CustomPlatformFile(
                    path: e.uri,
                    name: e.name,
                    size: e.size,
                    lastModified: e.lastModified,
                    mimeType: e.type,
                  ))
              .toList();
          _notifyEvent(
            DropDoneEvent(location: _offset ?? Offset.zero, files: results!),
          );
          _offset = null;
        }
        break;
      case "stream":
        try {
          if (results != null) {
            var fileName = call.arguments[0];
            var file =
                results!.firstWhere((element) => element.name == fileName);
            var data = call.arguments[1];
            file.stream(data, data == null ? call.arguments[2] : '');
          }
        } catch (e, s) {
          debugPrint('_handleMethodChannel: $e $s');
        }
        break;
      default:
        throw UnimplementedError('${call.method} not implement.');
    }
  }

  void _notifyEvent(DropEvent event) {
    for (final listener in _listeners) {
      listener(event);
    }
  }

  void addRawDropEventListener(RawDropListener listener) {
    assert(!_listeners.contains(listener));
    _listeners.add(listener);
  }

  void removeRawDropEventListener(RawDropListener listener) {
    assert(_listeners.contains(listener));
    _listeners.remove(listener);
  }
}
