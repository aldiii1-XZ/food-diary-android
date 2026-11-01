import 'dart:typed_data';

/// Di perangkat (Android/iOS/desktop) `image_picker` sudah mengecilkan foto
/// lewat `maxWidth: 1600` + `imageQuality: 88`, jadi tidak perlu diproses lagi.
Future<({Uint8List bytes, String ext})> kecilkanFoto(
  Uint8List bytes,
  String ext, {
  int sisiMaks = 1600,
  int batasLewat = 800 * 1024,
  double mutu = 0.85,
}) async =>
    (bytes: bytes, ext: ext);
