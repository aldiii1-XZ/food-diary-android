import '../models/food_entry.dart';

/// Angka kalori satu catatan. Pakai field [FoodEntry.kcal]; kalau kosong,
/// baca dari catatan teks — catatan hasil "Kenali dari foto" menuliskan
/// kalorinya di situ (mis. "1 piring · ±650 kkal").
int? kaloriCatatan(FoodEntry e) {
  final angka = e.kcal;
  if (angka != null && angka > 0) return angka;
  final cocok =
      RegExp(r'([0-9][0-9.]{0,7})\s*kkal', caseSensitive: false).firstMatch(e.note);
  if (cocok == null) return null;
  final nilai = int.tryParse(cocok.group(1)!.replaceAll('.', ''));
  return (nilai != null && nilai > 0) ? nilai : null;
}

/// Ringkasan kalori satu hari dari daftar catatan.
class RingkasanKalori {
  const RingkasanKalori({
    required this.total,
    required this.terhitung,
    required this.tanpaAngka,
    this.batas,
  });

  /// Total kalori catatan yang punya angka.
  final int total;

  /// Jumlah catatan yang ikut dihitung.
  final int terhitung;

  /// Jumlah catatan tanpa angka kalori (tidak ikut dijumlahkan).
  final int tanpaAngka;

  /// Batas harian; null = belum diatur.
  final int? batas;

  bool get adaBatas => batas != null && batas! > 0;

  bool get lewatBatas => adaBatas && total > batas!;

  /// Sisa kalori; negatif berarti sudah lewat batas.
  int? get sisa => adaBatas ? batas! - total : null;

  /// 0..1 untuk bilah kemajuan.
  double get progres => adaBatas ? (total / batas!).clamp(0.0, 1.0) : 0.0;
}

RingkasanKalori ringkasKalori(List<FoodEntry> catatan, {int? batas}) {
  var total = 0;
  var terhitung = 0;
  var tanpaAngka = 0;
  for (final e in catatan) {
    final k = kaloriCatatan(e);
    if (k == null) {
      tanpaAngka++;
    } else {
      total += k;
      terhitung++;
    }
  }
  return RingkasanKalori(
    total: total,
    terhitung: terhitung,
    tanpaAngka: tanpaAngka,
    batas: batas,
  );
}
