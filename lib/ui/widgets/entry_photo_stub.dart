import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'photo_placeholder.dart';

/// Versi web: foto dari data URL base64 yang disiapkan WebEntryStore.
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

  /// ponytail: simpan hasil decode supaya tidak diulang tiap rebuild
  /// (Image.memory mencocokkan cache berdasarkan bytes yang sama).
  static final Map<String, Uint8List> _terdekode = {};

  static Uint8List? _bytes(String dataUrl) {
    final ada = _terdekode[dataUrl];
    if (ada != null) return ada;
    final bytes = base64Decode(dataUrl.substring(dataUrl.indexOf(',') + 1));
    if (_terdekode.length > 80) _terdekode.clear();
    return _terdekode[dataUrl] = bytes;
  }

  @override
  Widget build(BuildContext context) {
    final p = path;
    final bytes = (p != null && p.startsWith('data:image/')) ? _bytes(p) : null;
    final child = bytes != null
        ? Image.memory(
            bytes,
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

/// Web: foto disimpan sebagai data URL base64; kembalikan isi bytesnya.
Future<Uint8List?> bacaBytesFoto(String? path) async {
  if (path == null || !path.startsWith('data:')) return null;
  final koma = path.indexOf(',');
  if (koma < 0) return null;
  try {
    return base64Decode(path.substring(koma + 1));
  } on FormatException {
    return null;
  }
}
