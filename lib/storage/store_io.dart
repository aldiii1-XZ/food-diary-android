import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../models/food_entry.dart';
import 'store_base.dart';

/// Penyimpanan nyata: satu file JSON + folder foto, di dalam folder data app.
///
/// Penulisan metadata memakai pola tulis-lalu-rename supaya file tidak pernah
/// setengah jadi kalau app mati di tengah proses.
class FileEntryStore implements EntryStore {
  FileEntryStore(this.rootDir);

  final Directory rootDir;

  File get _file => File(p.join(rootDir.path, 'entries.json'));
  Directory get _photosDir => Directory(p.join(rootDir.path, 'photos'));

  @override
  Future<List<FoodEntry>> load() async {
    if (!await _file.exists()) return [];
    try {
      final raw = await _file.readAsString();
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final list = (data['entries'] as List?) ?? const [];
      return list
          .map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on Exception {
      // File rusak: JANGAN timpa. Ganti nama jadi cadangan supaya masih bisa
      // diselamatkan manual, lalu mulai dari daftar kosong.
      try {
        await _file.rename(
          '${_file.path}.rusak-${DateTime.now().millisecondsSinceEpoch}',
        );
      } catch (_) {}
      return [];
    }
  }

  @override
  Future<void> saveAll(List<FoodEntry> entries) async {
    await rootDir.create(recursive: true);
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(
      jsonEncode({
        'version': 1,
        'entries': [for (final e in entries) e.toJson()],
      }),
      flush: true,
    );
    await tmp.rename(_file.path);
  }

  @override
  String photoPath(String fileName) => p.join(_photosDir.path, fileName);

  @override
  Future<String> addPhoto(List<int> bytes, String extension) async {
    await _photosDir.create(recursive: true);
    final bersih = RegExp(r'^[a-zA-Z0-9]{1,5}$').hasMatch(extension)
        ? extension.toLowerCase()
        : 'jpg';
    final nama = 'foto-${DateTime.now().microsecondsSinceEpoch}.$bersih';
    await File(photoPath(nama)).writeAsBytes(bytes, flush: true);
    return nama;
  }

  @override
  Future<void> deletePhoto(String fileName) async {
    final file = File(photoPath(fileName));
    if (await file.exists()) await file.delete();
  }
}
