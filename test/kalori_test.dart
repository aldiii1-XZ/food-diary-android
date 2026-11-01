import 'package:flutter_test/flutter_test.dart';
import 'package:food_diary/models/food_entry.dart';
import 'package:food_diary/support/kalori.dart';

FoodEntry e({int? kcal, String note = ''}) => FoodEntry(
      id: 'x',
      note: note,
      kcal: kcal,
      consumedAt: DateTime(2026, 11, 1, 12),
    );

void main() {
  test('angka dari field kcal dipakai lebih dulu', () {
    expect(kaloriCatatan(e(kcal: 650, note: '±250 kkal')), 650);
  });

  test('catatan lama dibaca dari teks "±650 kkal"', () {
    expect(kaloriCatatan(e(note: '1 piring · ±650 kkal')), 650);
  });

  test('"1.250 kkal" dibaca seribu dua ratus lima puluh', () {
    expect(kaloriCatatan(e(note: 'porsi besar, 1.250 kkal')), 1250);
  });

  test('tanpa angka kalori: null', () {
    expect(kaloriCatatan(e(note: 'enak, murah')), isNull);
    expect(kaloriCatatan(e()), isNull);
    expect(kaloriCatatan(e(note: 'kalori: banyak')), isNull);
  });

  test('ringkasan: menjumlah, menghitung yang tanpa angka, sisa', () {
    final r = ringkasKalori(
      [e(kcal: 600), e(note: '200 kkal'), e(note: 'tanpa info')],
      batas: 1000,
    );
    expect(r.total, 800);
    expect(r.terhitung, 2);
    expect(r.tanpaAngka, 1);
    expect(r.lewatBatas, isFalse);
    expect(r.sisa, 200);
    expect(r.progres, closeTo(0.8, 0.001));
  });

  test('lewat batas terdeteksi dan progres mentok di 1', () {
    final r = ringkasKalori([e(kcal: 2200)], batas: 2000);
    expect(r.lewatBatas, isTrue);
    expect(r.sisa, -200);
    expect(r.progres, 1.0);
  });

  test('tanpa batas: hitungan tetap jalan, status batas mati', () {
    final r = ringkasKalori([e(kcal: 500)]);
    expect(r.total, 500);
    expect(r.adaBatas, isFalse);
    expect(r.lewatBatas, isFalse);
    expect(r.sisa, isNull);
    expect(r.progres, 0.0);
  });
}
