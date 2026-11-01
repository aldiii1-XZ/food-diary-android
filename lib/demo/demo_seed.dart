import '../models/food_entry.dart';

/// Data contoh untuk pratinjau tampilan (bukan dipakai di app asli).
List<FoodEntry> demoEntries(DateTime sekarang) {
  final awalHariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
  final kemarinPagi = awalHariIni
      .subtract(const Duration(days: 1))
      .add(const Duration(hours: 8, minutes: 15));
  return [
    FoodEntry(
      id: 'demo-1',
      name: 'Kopi susu',
      note: 'Tanpa gula',
      consumedAt: sekarang.subtract(const Duration(hours: 3)),
    ),
    FoodEntry(
      id: 'demo-2',
      name: 'Mie ayam',
      note: 'Porsi kecil, kuah dipisah',
      consumedAt: sekarang.subtract(const Duration(hours: 1)),
    ),
    FoodEntry(
      id: 'demo-3',
      name: 'Nasi goreng',
      note: 'Sarapan kemarin',
      consumedAt: kemarinPagi,
    ),
  ];
}
