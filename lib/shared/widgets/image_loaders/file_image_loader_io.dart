import 'dart:io';

import 'package:flutter/material.dart';

Widget? getPlatformFileImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  WidgetBuilder? errorBuilder,
}) {
  try {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: errorBuilder != null ? (c, e, s) => errorBuilder(c) : null,
      );
    }
  } catch (_) {}
  return null;
}
