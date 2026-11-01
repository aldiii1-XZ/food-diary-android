import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:food_diary/models/food_entry.dart';
import 'package:food_diary/storage/store_io.dart';

void main() {
  late Directory tmp;
  late FileEntryStore store;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('food_diary_store');
    store = FileEntryStore(Directory('${tmp.path}/data'));
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('simpan lalu buka ulang: catatan tetap ada', () async {
    final entry = FoodEntry(
      id: '1',
      name: 'Kopi susu',
      note: 'tanpa gula',
      consumedAt: DateTime(2026, 11, 1, 7, 30),
    );
    await store.saveAll([entry]);

    // "restart": instance baru membaca folder yang sama
    final storeBaru = FileEntryStore(Directory('${tmp.path}/data'));
    final lagi = await storeBaru.load();

    expect(lagi.length, 1);
    expect(lagi.first.name, 'Kopi susu');
    expect(lagi.first.consumedAt, DateTime(2026, 11, 1, 7, 30));
  });

  test('belum pernah menyimpan: daftar kosong', () async {
    expect(await store.load(), isEmpty);
  });

  test('file rusak tidak menghapus apa pun: diganti nama jadi cadangan',
      () async {
    final dataDir = Directory('${tmp.path}/data');
    await dataDir.create(recursive: true);
    final file = File('${dataDir.path}/entries.json');
    await file.writeAsString('{rusak banget');

    final hasil = await store.load();

    expect(hasil, isEmpty);
    expect(await file.exists(), isFalse);
    final adaCadangan =
        dataDir.listSync().any((f) => f.path.contains('.rusak-'));
    expect(adaCadangan, isTrue);
  });

  test('foto ditulis dan dihapus dari disk', () async {
    final nama = await store.addPhoto([1, 2, 3, 4], 'JPG');
    final path = store.photoPath(nama);

    expect(nama.endsWith('.jpg'), isTrue);
    expect(await File(path).exists(), isTrue);
    expect(await File(path).readAsBytes(), [1, 2, 3, 4]);

    await store.deletePhoto(nama);
    expect(await File(path).exists(), isFalse);
  });

  test('ekstensi aneh diganti jadi jpg', () async {
    final nama = await store.addPhoto([0], 'php/*');
    expect(nama.endsWith('.jpg'), isTrue);
  });

  test('batas kalori: belum ada, tersimpan, lalu dihapus', () async {
    expect(await store.loadBatasKalori(), isNull);

    await store.saveBatasKalori(1800);
    expect(await store.loadBatasKalori(), 1800);

    // "restart": instance baru membaca folder yang sama
    final storeBaru = FileEntryStore(Directory('${tmp.path}/data'));
    expect(await storeBaru.loadBatasKalori(), 1800);

    await store.saveBatasKalori(null);
    expect(await store.loadBatasKalori(), isNull);
  });

  test('setelan rusak tidak bikin gagal', () async {
    final dataDir = Directory('${tmp.path}/data');
    await dataDir.create(recursive: true);
    await File('${dataDir.path}/setelan.json').writeAsString('{rusak');
    expect(await store.loadBatasKalori(), isNull);
  });
}
