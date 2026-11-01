import 'package:flutter/material.dart';

import 'photo_placeholder.dart';

/// Versi web/pratinjau: tanpa akses file, selalu kotak pengganti.
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: const PhotoPlaceholder(),
      ),
    );
  }
}
