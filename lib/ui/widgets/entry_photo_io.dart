import 'dart:io';

import 'package:flutter/material.dart';

import 'photo_placeholder.dart';

/// Foto catatan dari file di perangkat.
class EntryPhoto extends StatelessWidget {
  const EntryPhoto({
    super.key,
    this.path,
    this.width,
    this.height,
    this.borderRadius = 10,
  });

  final String? path;
  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final p = path;
    final adaFoto = p != null && p.isNotEmpty;
    final child = adaFoto
        ? Image(
            image: FileImage(File(p)),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const PhotoPlaceholder(),
          )
        : const PhotoPlaceholder();
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: width, height: height, child: child),
    );
  }
}
