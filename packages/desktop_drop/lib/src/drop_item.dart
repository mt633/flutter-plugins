import 'dart:typed_data';

class WebDropItem {
  WebDropItem({
    required this.uri,
    required this.name,
    required this.type,
    required this.size,
    required this.relativePath,
    required this.lastModified,
    this.bytes,
  });

  final String uri;
  final String name;
  final String type;
  final int size;
  final String? relativePath;
  final DateTime lastModified;
  final Uint8List? bytes;

  factory WebDropItem.fromJson(Map<String, dynamic> json) => WebDropItem(
        uri: json['uri'],
        name: json['name'],
        type: json['type'],
        size: json['size'],
        bytes: json['bytes'],
        relativePath: json['relativePath'],
        lastModified: DateTime.fromMillisecondsSinceEpoch(json['lastModified']),
      );

  Map toJson() => {
        'uri': uri,
        'name': name,
        'type': type,
        'size': size,
        'relativePath': relativePath,
        'bytes': bytes,
        'lastModified': lastModified.millisecondsSinceEpoch,
      };
}
