import '../models/food_entry.dart';

/// Antarmuka penyimpanan catatan.
///
/// [FileEntryStore] (store_io.dart) menyimpan ke file di perangkat.
/// [MemoryEntryStore] (store_memory.dart) untuk halaman pratinjau (web/demo).
abstract class EntryStore {
  Future<List<FoodEntry>> load();

  Future<void> saveAll(List<FoodEntry> entries);

  Future<String> addPhoto(List<int> bytes, String extension);

  Future<void> deletePhoto(String fileName);

  /// Path lengkap file foto supaya bisa ditampilkan; versi memori mengembalikan ''.
  String photoPath(String fileName);

  /// Batas kalori harian; null = belum diatur.
  Future<int?> loadBatasKalori();

  Future<void> saveBatasKalori(int? batas);
}
