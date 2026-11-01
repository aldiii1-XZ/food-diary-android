const List<String> namaBulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

String angkaDua(int n) => n.toString().padLeft(2, '0');

String formatJam(DateTime t) => '${angkaDua(t.hour)}:${angkaDua(t.minute)}';

String formatTanggal(DateTime d) => '${d.day} ${namaBulan[d.month - 1]} ${d.year}';

bool tanggalSama(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// "Hari Ini" / "Kemarin" / "1 November 2026".
String labelHari(DateTime hari, DateTime sekarang) {
  final awalHariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
  final awalTanggal = DateTime(hari.year, hari.month, hari.day);
  final beda = awalHariIni.difference(awalTanggal).inDays;
  if (beda == 0) return 'Hari Ini';
  if (beda == 1) return 'Kemarin';
  return formatTanggal(hari);
}

/// "07:30" atau "01:36–03:36" dari daftar waktu.
String rentangJam(List<DateTime> times) {
  if (times.isEmpty) return '';
  final urut = [...times]..sort();
  if (urut.length == 1) return formatJam(urut.first);
  return '${formatJam(urut.first)}–${formatJam(urut.last)}';
}
