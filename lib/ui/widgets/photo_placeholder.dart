import 'package:flutter/material.dart';

/// Kotak pengganti saat foto tidak ada atau tidak terbaca.
class PhotoPlaceholder extends StatelessWidget {
  const PhotoPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, batas) {
        final sisi = batas.biggest.shortestSide;
        final ukuranIkon = sisi.isFinite ? (sisi * 0.4).clamp(16.0, 44.0) : 24.0;
        return ColoredBox(
          color: scheme.surfaceContainerHighest,
          child: Center(
            child: Icon(Icons.restaurant_outlined,
                color: scheme.outline, size: ukuranIkon),
          ),
        );
      },
    );
  }
}
