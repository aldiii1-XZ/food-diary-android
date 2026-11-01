import '../models/food_entry.dart';
import 'store_base.dart';

/// Penyimpanan dalam memori — untuk halaman pratinjau (web) dan demo.
///
/// ponytail: tidak menulis file sama sekali; cukup untuk pratinjau tampilan,
/// jangan dipakai di HP. Versi nyata: FileEntryStore di store_io.dart.
class MemoryEntryStore implements EntryStore {
  MemoryEntryStore([List<FoodEntry>? awal]) : _entries = [...?awal];

  final List<FoodEntry> _entries;
  int _fotoKe = 0;
  int? _batas;

  @override
  Future<List<FoodEntry>> load() async => [..._entries];

  @override
  Future<void> saveAll(List<FoodEntry> entries) async {
    _entries
      ..clear()
      ..addAll(entries);
  }

  @override
  Future<String> addPhoto(List<int> bytes, String extension) async =>
      'memori-${++_fotoKe}.jpg';

  @override
  Future<void> deletePhoto(String fileName) async {}

  @override
  String photoPath(String fileName) => '';

  @override
  Future<int?> loadBatasKalori() async => _batas;

  @override
  Future<void> saveBatasKalori(int? batas) async => _batas = batas;
}
