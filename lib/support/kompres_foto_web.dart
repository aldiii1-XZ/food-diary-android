import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Di web `image_picker` mengabaikan `maxWidth`/`imageQuality`, jadi foto
/// galeri datang mentah (bisa 3–12 MB) dan server AI menolaknya
/// (HTTP 413 FUNCTION_PAYLOAD_TOO_LARGE — batas body Vercel 4,5 MB).
/// Kecilkan lewat canvas: maks [sisiMaks] px, JPEG mutu [mutu].
///
/// ponytail: kalau browser tak bisa mendekode (mis. HEIC), kirim aslinya —
/// pengguna dapat pesan "fotonya terlalu besar" dari endpoint, bukan crash.
Future<({Uint8List bytes, String ext})> kecilkanFoto(
  Uint8List bytes,
  String ext, {
  int sisiMaks = 1600,
  int batasLewat = 800 * 1024,
  double mutu = 0.85,
}) async {
  final asli = (bytes: bytes, ext: ext);
  if (bytes.length <= batasLewat) return asli;
  try {
    final mime = switch (ext.toLowerCase()) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    final img = web.HTMLImageElement();
    // Jangan pakai img.decode(): di Chromium bisa menggantung untuk data URL
    // besar — event load/error selalu terbit.
    final siap = Completer<void>();
    void tandai(web.Event _) {
      if (!siap.isCompleted) siap.complete();
    }

    img.addEventListener('load', ((web.Event e) => tandai(e)).toJS);
    img.addEventListener('error', ((web.Event e) => tandai(e)).toJS);
    img.src = 'data:$mime;base64,${base64Encode(bytes)}';
    await siap.future.timeout(const Duration(seconds: 20));
    final w = img.naturalWidth;
    final h = img.naturalHeight;
    if (w <= 0 || h <= 0) return asli;
    final maks = w > h ? w : h;
    final skala = maks > sisiMaks ? sisiMaks / maks : 1.0;
    final tw = (w * skala).round();
    final th = (h * skala).round();
    final canvas = web.HTMLCanvasElement()
      ..width = tw
      ..height = th;
    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    ctx.drawImage(img, 0, 0, tw, th);
    final dataUrl = canvas.toDataURL('image/jpeg', mutu.toJS);
    final koma = dataUrl.indexOf(',');
    if (koma < 0) return asli;
    final kecil = base64Decode(dataUrl.substring(koma + 1));
    if (kecil.isEmpty || kecil.length >= bytes.length) return asli;
    return (bytes: kecil, ext: 'jpg');
  } catch (_) {
    return asli;
  }
}
