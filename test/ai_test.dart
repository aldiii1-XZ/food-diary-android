import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_diary/ai/ai_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HasilKenali', () {
    test('membaca JSON rapi dari model', () {
      final h = HasilKenali.dariTeks(
          '{"nama":"Nasi goreng","porsi":"1 piring","kalori":"650"}');
      expect(h.nama, 'Nasi goreng');
      expect(h.ringkasan, '1 piring · ±650 kkal');
    });

    test('tahan pagar kode markdown', () {
      final h = HasilKenali.dariTeks(
          '```json\n{"nama":"Sate ayam","porsi":"10 tusuk","kalori":"400 kkal"}\n```');
      expect(h.nama, 'Sate ayam');
      expect(h.ringkasan, '10 tusuk · ±400 kkal');
    });

    test('bukan JSON - pakai baris pertama', () {
      final h = HasilKenali.dariTeks('Sepertinya ini mie goreng.\nAda telur.');
      expect(h.nama, 'Sepertinya ini mie goreng.');
      expect(h.ringkasan, '');
    });
  });

  group('AiClient', () {
    test('kenaliFoto mengirim data URL gambar + membaca balasan', () async {
      String? badan;
      final klien = MockClient((req) async {
        badan = req.body;
        return http.Response(
          jsonEncode({
            'text': '{"nama":"Nasi goreng","porsi":"1 piring","kalori":"650"}'
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });
      final ai = AiClient(endpoint: 'http://contoh.test/api/ai', klien: klien);
      final hasil = await ai.kenaliFoto(Uint8List.fromList([1, 2, 3]));

      expect(hasil.nama, 'Nasi goreng');
      final kirim = jsonDecode(badan!) as Map<String, dynamic>;
      final pesan = (kirim['messages'] as List).first as Map<String, dynamic>;
      final isi = pesan['content'] as List;
      expect(isi, hasLength(2));
      expect((isi.last as Map)['type'], 'image_url');
      final url = ((isi.last as Map)['image_url'] as Map)['url'] as String;
      expect(url, startsWith('data:image/jpeg;base64,'));
    });

    test('balasan error server jadi AiError yang enak dibaca', () async {
      final klien = MockClient((req) async => http.Response(
            jsonEncode({'error': 'Terlalu banyak permintaan, coba sebentar lagi'}),
            429,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ));
      final ai = AiClient(endpoint: 'http://contoh.test/api/ai', klien: klien);
      expect(
        () => ai.tanya([
          {'role': 'user', 'content': 'hai'}
        ]),
        throwsA(isA<AiError>()
            .having((e) => e.pesan, 'pesan', contains('Terlalu banyak'))),
      );
    });
  });
}
