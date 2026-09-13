import 'dart:io';

String sanitizeDownloadFileName(String fileName) {
  var name = fileName.split(RegExp(r'[/\\]')).last;
  name = name.split('?').first.split('#').first;
  name = name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  if (name.isEmpty || name == '.' || name == '..') {
    return 'download.bin';
  }
  if (name.length > 120) {
    name = name.substring(name.length - 120);
  }
  return name;
}

String resolveTempSavePath(Directory tempDir, String fileName) {
  return resolveSafeSavePath(tempDir, fileName);
}

String resolveDocumentsSavePath(Directory documentsDir, String fileName) {
  return resolveSafeSavePath(documentsDir, fileName);
}

String resolveSafeSavePath(Directory dir, String fileName) {
  final safeName = sanitizeDownloadFileName(fileName);
  final file = File('${dir.path}${Platform.pathSeparator}$safeName');
  final rootPath = dir.path.endsWith(Platform.pathSeparator)
      ? dir.path
      : '${dir.path}${Platform.pathSeparator}';
  if (!file.path.startsWith(rootPath)) {
    throw Exception('Некоректний шлях завантаження');
  }
  return file.path;
}
