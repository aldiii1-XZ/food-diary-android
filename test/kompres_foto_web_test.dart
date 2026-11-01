@TestOn('browser')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_diary/support/kompres_foto.dart';
import 'package:web/web.dart' as web;

/// Foto "galeri HP": noise acak 2600x1950 JPEG q95 — beberapa MB, persis
/// jenis foto yang dulu bikin server membalas HTTP 413.
Uint8List _fotoBesar() {
  final canvas = web.HTMLCanvasElement()
    ..width = 2600
    ..height = 1950;
  final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
  final gambar = ctx.createImageData(2600.toJS, 1950);
  final data = gambar.data.toDart;
  var x = 123456789;
  for (var i = 0; i < data.length; i += 4) {
    x = (1103515245 * x + 12345) & 0x7FFFFFFF;
    data[i] = x & 0xFF;
    data[i + 1] = (x >> 8) & 0xFF;
    data[i + 2] = (x >> 16) & 0xFF;
    data[i + 3] = 255;
  }
  ctx.putImageData(web.ImageData(data.toJS, 2600, 1950.toJS), 0, 0);
  final dataUrl = canvas.toDataURL('image/jpeg', 0.95.toJS);
  return base64Decode(dataUrl.substring(dataUrl.indexOf(',') + 1));
}

void main() {
  test('foto besar dikecilkan sampai aman dikirim (jauh bawah 4,5 MB)', () async {
    final besar = _fotoBesar();
    expect(besar.length, greaterThan(3 * 1024 * 1024),
        reason: 'input uji harus benar-benar besar');

    final hasil = await kecilkanFoto(besar, 'jpg');
    expect(hasil.ext, 'jpg');
    expect(hasil.bytes.length, lessThan(besar.length));
    // Body kirim = base64 (~4/3 ukuran byte) harus di bawah batas body Vercel 4,5 MB.
    expect(hasil.bytes.length * 4 / 3, lessThan(4.5 * 1024 * 1024));

    // Hasil masih foto sah & dimensi maksimal 1600 px.
    final img = web.HTMLImageElement();
    final siap = Completer<void>();
    img.addEventListener('load', ((web.Event e) => siap.complete()).toJS);
    img.addEventListener('error', ((web.Event e) => siap.complete()).toJS);
    img.src = 'data:image/jpeg;base64,${base64Encode(hasil.bytes)}';
    await siap.future.timeout(const Duration(seconds: 10));
    expect(img.naturalWidth, lessThanOrEqualTo(1600));
    expect(img.naturalHeight, lessThanOrEqualTo(1600));
    expect(img.naturalWidth, greaterThan(0));
  });

  test('foto kecil dibiarkan apa adanya', () async {
    final canvas = web.HTMLCanvasElement()
      ..width = 120
      ..height = 90;
    final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    ctx.fillStyle = 'orange'.toJS;
    ctx.fillRect(0, 0, 120, 90);
    final dataUrl = canvas.toDataURL('image/jpeg', 0.5.toJS);
    final kecil = base64Decode(dataUrl.substring(dataUrl.indexOf(',') + 1));
    expect(kecil.length, lessThan(800 * 1024));

    final hasil = await kecilkanFoto(kecil, 'jpg');
    expect(hasil.bytes.length, kecil.length);
    expect(hasil.ext, 'jpg');
  });
}
