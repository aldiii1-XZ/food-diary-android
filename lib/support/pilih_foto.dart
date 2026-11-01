import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Buka pilihan kamera/galeri lalu kembalikan bytes foto.
/// Mengembalikan null kalau dibatalkan.
Future<({Uint8List bytes, String extension})?> pilihFoto(
  BuildContext context,
) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Ambil Foto'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih dari Galeri'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (source == null) return null;
  final file = await ImagePicker().pickImage(
    source: source,
    maxWidth: 1600,
    imageQuality: 88,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  final ext = file.name.contains('.') ? file.name.split('.').last : 'jpg';
  return (bytes: bytes, extension: ext);
}
