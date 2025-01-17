import 'package:flutter/painting.dart';

import '../desktop_drop.dart';

abstract class DropEvent {
  Offset location;

  DropEvent(this.location);

  @override
  String toString() {
    return '$runtimeType($location)';
  }
}

class DropEnterEvent extends DropEvent {
  DropEnterEvent({required Offset location}) : super(location);
}

class DropExitEvent extends DropEvent {
  DropExitEvent({required Offset location}) : super(location);
}

class DropUpdateEvent extends DropEvent {
  DropUpdateEvent({required Offset location}) : super(location);
}

class DropDoneEvent extends DropEvent {
  final List<CustomPlatformFile> files;

  DropDoneEvent({
    required Offset location,
    required this.files,
  }) : super(location);

  @override
  String toString() {
    return '$runtimeType($location, $files)';
  }
}
