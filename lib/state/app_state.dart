import 'package:flutter/foundation.dart';

import '../models/food_entry.dart';
import '../storage/store_base.dart';
import '../support/format.dart';

/// State global aplikasi: daftar catatan + operasi simpan/ubah/hapus.
///
/// Aturan integritas data (sama seperti versi iOS):
/// 1. File foto ditulis lebih dulu, baru metadata disimpan.
/// 2. Kalau penyimpanan metadata gagal, perubahan di memori dibatalkan.
/// 3. File foto lama baru dihapus setelah metadata baru benar-benar tersimpan.
class AppState extends ChangeNotifier {
  AppState(this.store);

  final EntryStore store;

  List<FoodEntry> _entries = [];
  bool _loading = true;
  String? _loadError;

  List<FoodEntry> get entries => List.unmodifiable(_entries);
  bool get isLoading => _loading;
  String? get loadError => _loadError;

  List<FoodEntry> get todayEntries => entriesOn(DateTime.now());

  List<FoodEntry> entriesOn(DateTime day) =>
      _entries.where((e) => tanggalSama(e.consumedAt, day)).toList();

  Future<void> init() async {
    _loading = true;
    _loadError = null;
    notifyListeners();
    try {
      _entries = await store.load();
      _sorted();
    } catch (e) {
      _loadError = 'Catatan tidak bisa dibuka: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createEntry({
    required List<int> photoBytes,
    required String photoExtension,
    required String name,
    required String note,
    required DateTime consumedAt,
  }) async {
    final photoFileName = await store.addPhoto(photoBytes, photoExtension);
    final entry = FoodEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(),
      note: note.trim(),
      consumedAt: consumedAt,
      photoFileName: photoFileName,
    );
    _entries.add(entry);
    _sorted();
    try {
      await store.saveAll(_entries);
    } catch (_) {
      _entries.removeWhere((e) => e.id == entry.id);
      await _deletePhotoQuietly(photoFileName);
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateEntry(
    String id, {
    String? name,
    String? note,
    DateTime? consumedAt,
    List<int>? newPhotoBytes,
    String? newPhotoExtension,
  }) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final entry = _entries[index];
    final oldName = entry.name;
    final oldNote = entry.note;
    final oldAt = entry.consumedAt;
    final oldPhoto = entry.photoFileName;

    String? addedPhoto;
    if (newPhotoBytes != null) {
      addedPhoto =
          await store.addPhoto(newPhotoBytes, newPhotoExtension ?? 'jpg');
      entry.photoFileName = addedPhoto;
    }
    if (name != null) entry.name = name.trim();
    if (note != null) entry.note = note.trim();
    if (consumedAt != null) entry.consumedAt = consumedAt;
    _sorted();
    try {
      await store.saveAll(_entries);
    } catch (_) {
      entry
        ..name = oldName
        ..note = oldNote
        ..consumedAt = oldAt
        ..photoFileName = oldPhoto;
      if (addedPhoto != null) await _deletePhotoQuietly(addedPhoto);
      rethrow;
    } finally {
      notifyListeners();
    }
    if (addedPhoto != null && oldPhoto != null && oldPhoto != addedPhoto) {
      await _deletePhotoQuietly(oldPhoto);
    }
  }

  Future<void> deleteEntry(String id) async {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index < 0) return;
    final removed = _entries.removeAt(index);
    _sorted();
    try {
      await store.saveAll(_entries);
    } catch (_) {
      _entries.insert(index, removed);
      _sorted();
      notifyListeners();
      rethrow;
    }
    notifyListeners();
    final photo = removed.photoFileName;
    if (photo != null) await _deletePhotoQuietly(photo);
  }

  void _sorted() =>
      _entries.sort((a, b) => b.consumedAt.compareTo(a.consumedAt));

  Future<void> _deletePhotoQuietly(String fileName) async {
    try {
      await store.deletePhoto(fileName);
    } catch (_) {
      // File sisa tidak fatal — lebih baik daripada membatalkan catatan.
    }
  }
}
