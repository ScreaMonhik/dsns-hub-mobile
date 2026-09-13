import 'dart:convert';
import 'dart:isolate';

Future<T> parseJsonMapInIsolate<T>(
  Object? data,
  T Function(Map<String, dynamic> json) fromJson,
) {
  final encoded = jsonEncode(data);
  return Isolate.run(() {
    final decoded = jsonDecode(encoded);
    return fromJson(Map<String, dynamic>.from(decoded as Map));
  });
}

Future<List<T>> parseJsonListInIsolate<T>(
  Object? data,
  T Function(Map<String, dynamic> json) fromJson,
) {
  final encoded = jsonEncode(data);
  return Isolate.run(() {
    final decoded = jsonDecode(encoded) as List<dynamic>;
    return decoded
        .map((item) => fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  });
}
