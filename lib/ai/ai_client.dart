import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Alamat endpoint AI. Bisa ditimpa saat build untuk pengujian lokal:
/// flutter build web --dart-define=AI_ENDPOINT=http://127.0.0.1:8791/api/ai
const String aiEndpoint = String.fromEnvironment(
  'AI_ENDPOINT',
  defaultValue: 'https://food-diary-android.vercel.app/api/ai',
);

class AiError implements Exception {
  AiError(this.pesan);

  final String pesan;

  @override
  String toString() => pesan;
}

/// Hasil identifikasi foto: nama singkat + keterangan porsi/kalori.
class HasilKenali {
  const HasilKenali({required this.nama, this.porsi = '', this.kalori = ''});

  final String nama;
  final String porsi;
  final String kalori;

  /// Ringkasan pendek untuk kolom catatan, mis. "1 piring · ±650 kkal".
  String get ringkasan {
    final angka = kalori.replaceAll(RegExp(r'[^0-9]'), '');
    final bagian = <String>[
      if (porsi.trim().isNotEmpty) porsi.trim(),
      if (angka.isNotEmpty) '±$angka kkal',
    ];
    return bagian.join(' · ');
  }

  /// Model diminta membalas JSON; kalau melenceng, pakai baris pertama apa
  /// adanya supaya kolom nama tetap terisi.
  static HasilKenali dariTeks(String teks) {
    final bersih = teks.replaceAll('```json', '```').replaceAll('```', '').trim();
    final mulai = bersih.indexOf('{');
    final selesai = bersih.lastIndexOf('}');
    if (mulai >= 0 && selesai > mulai) {
      try {
        final data = jsonDecode(bersih.substring(mulai, selesai + 1));
        if (data is Map) {
          final nama = (data['nama'] ?? data['name'] ?? '').toString().trim();
          if (nama.isNotEmpty && nama.length <= 80) {
            return HasilKenali(
              nama: nama,
              porsi: (data['porsi'] ?? '').toString().trim(),
              kalori: (data['kalori'] ?? data['estimasi_kalori'] ?? '')
                  .toString()
                  .trim(),
            );
          }
        }
      } on FormatException {
        // jatuh ke cara kasar di bawah
      }
    }
    final baris = bersih
        .split('\n')
        .firstWhere((b) => b.trim().isNotEmpty, orElse: () => '')
        .trim();
    return HasilKenali(nama: baris.length > 80 ? baris.substring(0, 80) : baris);
  }
}

class AiClient {
  AiClient({String? endpoint, http.Client? klien})
      : _endpoint = endpoint ?? aiEndpoint,
        _http = klien ?? http.Client();

  final String _endpoint;
  final http.Client _http;

  /// Kirim percakapan ke endpoint AI; hasilnya teks jawaban.
  Future<String> kirim(List<Map<String, dynamic>> messages) async {
    late final http.Response r;
    try {
      r = await _http
          .post(
            Uri.parse(_endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'messages': messages}),
          )
          .timeout(const Duration(seconds: 90));
    } on Exception catch (e) {
      throw AiError('Tidak bisa menghubungi AI: $e');
    }
    Map<String, dynamic> data = const {};
    try {
      final hasil = jsonDecode(utf8.decode(r.bodyBytes));
      if (hasil is Map<String, dynamic>) data = hasil;
    } on FormatException {
      // balasan bukan JSON; ditangani lewat statusCode di bawah
    }
    if (r.statusCode != 200) {
      if (r.statusCode == 413) {
        throw AiError('Fotonya terlalu besar untuk dikirim. Coba foto lain.');
      }
      throw AiError(
        (data['error'] ?? 'AI membalas HTTP ${r.statusCode}').toString(),
      );
    }
    final teks = (data['text'] ?? '').toString().trim();
    if (teks.isEmpty) throw AiError('AI tidak mengirim jawaban');
    return teks;
  }

  /// Tanya-jawab biasa; [riwayat] = daftar {role, content}.
  Future<String> tanya(List<Map<String, dynamic>> riwayat) => kirim(riwayat);

  /// Kenali makanan dari foto.
  Future<HasilKenali> kenaliFoto(Uint8List bytes, {String mime = 'image/jpeg'}) async {
    if (bytes.isEmpty) throw AiError('Fotonya kosong');
    final teks = await kirim([
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': 'Makanan apa ini?'},
          {
            'type': 'image_url',
            'image_url': {'url': 'data:$mime;base64,${base64Encode(bytes)}'},
          },
        ],
      },
    ]);
    return HasilKenali.dariTeks(teks);
  }
}
