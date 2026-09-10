import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

Rect? shareOriginOf(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

Future<void> shareText(BuildContext context, String text, {String? subject}) {
  return Share.share(
    text,
    subject: subject,
    sharePositionOrigin: shareOriginOf(context),
  );
}

Future<void> shareFiles(BuildContext context, List<XFile> files, {String? text}) {
  return Share.shareXFiles(
    files,
    text: text,
    sharePositionOrigin: shareOriginOf(context),
  );
}
