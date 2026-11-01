import 'package:flutter_test/flutter_test.dart';
import 'package:food_diary/models/food_entry.dart';

void main() {
  test('bolak-balik JSON tetap sama', () {
    final awal = FoodEntry(
      id: '1',
      name: 'Kopi susu',
      note: 'tanpa gula',
      consumedAt: DateTime(2026, 11, 1, 7, 30),
      photoFileName: 'foto-1.jpg',
    );

    final lagi = FoodEntry.fromJson(awal.toJson());

    expect(lagi.id, '1');
    expect(lagi.name, 'Kopi susu');
    expect(lagi.note, 'tanpa gula');
    expect(lagi.consumedAt, DateTime(2026, 11, 1, 7, 30));
    expect(lagi.photoFileName, 'foto-1.jpg');
  });

  test('kunci yang hilang tidak membuat gagal', () {
    final e = FoodEntry.fromJson({
      'id': '2',
      'consumedAt': '2026-11-01T07:30:00.000',
    });

    expect(e.name, '');
    expect(e.note, '');
    expect(e.photoFileName, isNull);
  });
}
