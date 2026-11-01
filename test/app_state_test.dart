import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_diary/models/food_entry.dart';
import 'package:food_diary/state/app_state.dart';
import 'package:food_diary/storage/store_io.dart';
import 'package:food_diary/storage/store_memory.dart';

/// Penyimpanan yang selalu gagal — untuk menguji jalur pemulihan.
class StoreGagal extends MemoryEntryStore {
  @override
  Future<void> saveAll(List<FoodEntry> entries) async {
    throw const FileSystemException('disk penuh (uji)');
  }
}

void main() {
  late Directory tmp;
  late FileEntryStore store;
  late AppState state;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('food_diary_state');
    store = FileEntryStore(Directory('${tmp.path}/data'));
    state = AppState(store);
    await state.init();
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  Future<void> catat(AppState s, String nama, DateTime waktu) =>
      s.createEntry(
        photoBytes: [9, 9],
        photoExtension: 'jpg',
        name: nama,
        note: '',
        consumedAt: waktu,
      );

  test('catatan tetap ada setelah app dibuka ulang', () async {
    await catat(state, 'Nasi goreng', DateTime.now());

    final lagi = AppState(FileEntryStore(Directory('${tmp.path}/data')));
    await lagi.init();

    expect(lagi.entries.length, 1);
    expect(lagi.entries.first.name, 'Nasi goreng');
    final foto = lagi.entries.first.photoFileName!;
    expect(await File(store.photoPath(foto)).exists(), isTrue);
  });

  test('hari ini hanya berisi catatan hari ini', () async {
    final sekarang = DateTime.now();
    await catat(state, 'Hari ini', sekarang);
    await catat(state, 'Minggu lalu',
        sekarang.subtract(const Duration(days: 7)));

    expect(state.todayEntries.length, 1);
    expect(state.todayEntries.first.name, 'Hari ini');
  });

  test('ubah catatan ikut tersimpan di disk', () async {
    await catat(state, 'Awal', DateTime.now());
    final id = state.entries.first.id;

    await state.updateEntry(id, name: 'Diubah', note: 'baru');

    final lagi = AppState(FileEntryStore(Directory('${tmp.path}/data')));
    await lagi.init();
    expect(lagi.entries.first.name, 'Diubah');
    expect(lagi.entries.first.note, 'baru');
  });

  test('hapus catatan: entri dan file fotonya hilang', () async {
    await catat(state, 'Mie ayam', DateTime.now());
    final entry = state.entries.first;
    final fotoPath = store.photoPath(entry.photoFileName!);
    expect(await File(fotoPath).exists(), isTrue);

    await state.deleteEntry(entry.id);

    expect(state.entries, isEmpty);
    expect(await File(fotoPath).exists(), isFalse);
    final lagi = AppState(FileEntryStore(Directory('${tmp.path}/data')));
    await lagi.init();
    expect(lagi.entries, isEmpty);
  });

  test('kalau penyimpanan gagal, tidak ada catatan palsu yang tertinggal',
      () async {
    final stateGagal = AppState(StoreGagal());
    await stateGagal.init();

    await expectLater(
      catat(stateGagal, 'X', DateTime.now()),
      throwsA(isA<FileSystemException>()),
    );

    expect(stateGagal.entries, isEmpty);
  });
}
