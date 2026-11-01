import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import '../models/food_entry.dart';
import 'store_base.dart';

/// Penyimpanan versi web (dipakai build Vercel).
///
/// Metadata catatan di localStorage; foto di IndexedDB, karena kuota
/// localStorage hanya ~5MB dan tidak cukup untuk beberapa foto.
///
/// Data hanya tersimpan di browser ini — tidak ada sinkronisasi antar
/// perangkat (itu butuh server).
class WebEntryStore implements EntryStore {
  static const _kunciCatatan = 'food_diary.entries';
  static const _kunciBatas = 'food_diary.batasKalori';
  static const _namaDb = 'food_diary';
  static const _tabelFoto = 'photos';

  /// nama file -> data URL siap pakai untuk EntryPhoto.
  final Map<String, String> _urlFoto = {};
  web.IDBDatabase? _db;

  Future<web.IDBDatabase> _bukaDb() async {
    final ada = _db;
    if (ada != null) return ada;
    final buka = web.window.indexedDB.open(_namaDb, 1);
    buka.onupgradeneeded = ((web.Event _) {
      final dbase = buka.result as web.IDBDatabase;
      if (!dbase.objectStoreNames.contains(_tabelFoto)) {
        dbase.createObjectStore(_tabelFoto);
      }
    }).toJS;
    final hasil = await _tunggu(buka);
    return _db = hasil as web.IDBDatabase;
  }

  Future<JSAny?> _tunggu(web.IDBRequest req) {
    final c = Completer<JSAny?>();
    req.onsuccess = ((web.Event _) => c.complete(req.result)).toJS;
    req.onerror = ((web.Event _) =>
            c.completeError(StateError('IndexedDB: ${req.error?.message}')))
        .toJS;
    return c.future;
  }

  Future<void> _tungguTx(web.IDBTransaction tx) {
    final c = Completer<void>();
    tx.oncomplete = ((web.Event _) => c.complete()).toJS;
    tx.onerror = ((web.Event _) =>
            c.completeError(StateError('IndexedDB: transaksi gagal')))
        .toJS;
    return c.future;
  }

  @override
  Future<List<FoodEntry>> load() async {
    final mentah = web.window.localStorage.getItem(_kunciCatatan);
    var daftar = <FoodEntry>[];
    if (mentah != null && mentah.isNotEmpty) {
      try {
        final data = jsonDecode(mentah) as Map<String, dynamic>;
        final list = (data['entries'] as List?) ?? const [];
        daftar = [
          for (final e in list) FoodEntry.fromJson(e as Map<String, dynamic>),
        ];
      } on Exception {
        // Data rusak: simpan salinannya (jangan timpa), mulai dari kosong.
        try {
          web.window.localStorage.setItem(
            '$_kunciCatatan.rusak-${DateTime.now().millisecondsSinceEpoch}',
            mentah,
          );
        } catch (_) {}
        daftar = [];
      }
    }
    await _muatFoto(daftar);
    return daftar;
  }

  Future<void> _muatFoto(List<FoodEntry> daftar) async {
    _urlFoto.clear();
    final nama = <String>{
      for (final e in daftar)
        if (e.photoFileName != null && e.photoFileName!.isNotEmpty)
          e.photoFileName!,
    };
    if (nama.isEmpty) return;
    final db = await _bukaDb();
    final tx = db.transaction(_tabelFoto.toJS, 'readonly');
    final tabel = tx.objectStore(_tabelFoto);
    for (final n in nama) {
      final data = (await _tunggu(tabel.get(n.toJS)))?.dartify();
      if (data is String && data.isNotEmpty) {
        _urlFoto[n] = 'data:${_mime(n)};base64,$data';
      }
    }
  }

  @override
  Future<void> saveAll(List<FoodEntry> entries) async {
    web.window.localStorage.setItem(
      _kunciCatatan,
      jsonEncode({
        'version': 1,
        'entries': [for (final e in entries) e.toJson()],
      }),
    );
  }

  @override
  String photoPath(String fileName) => _urlFoto[fileName] ?? '';

  @override
  Future<String> addPhoto(List<int> bytes, String extension) async {
    final bersih = RegExp(r'^[a-zA-Z0-9]{1,5}$').hasMatch(extension)
        ? extension.toLowerCase()
        : 'jpg';
    final nama = 'foto-${DateTime.now().microsecondsSinceEpoch}.$bersih';
    final b64 = base64Encode(bytes);
    final db = await _bukaDb();
    final tx = db.transaction(_tabelFoto.toJS, 'readwrite');
    tx.objectStore(_tabelFoto).put(b64.toJS, nama.toJS);
    await _tungguTx(tx);
    _urlFoto[nama] = 'data:${_mime(nama)};base64,$b64';
    return nama;
  }

  @override
  Future<void> deletePhoto(String fileName) async {
    _urlFoto.remove(fileName);
    final db = await _bukaDb();
    final tx = db.transaction(_tabelFoto.toJS, 'readwrite');
    tx.objectStore(_tabelFoto).delete(fileName.toJS);
    await _tungguTx(tx);
  }

  @override
  Future<int?> loadBatasKalori() async {
    final s = web.window.localStorage.getItem(_kunciBatas);
    final v = s == null ? null : int.tryParse(s);
    return (v != null && v > 0) ? v : null;
  }

  @override
  Future<void> saveBatasKalori(int? batas) async {
    if (batas == null || batas <= 0) {
      web.window.localStorage.removeItem(_kunciBatas);
    } else {
      web.window.localStorage.setItem(_kunciBatas, '$batas');
    }
  }

  String _mime(String nama) {
    final titik = nama.lastIndexOf('.');
    final ext = titik < 0 ? 'jpg' : nama.substring(titik + 1).toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      'bmp' => 'image/bmp',
      _ => 'image/jpeg',
    };
  }
}
