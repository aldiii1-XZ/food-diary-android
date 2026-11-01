import 'package:flutter_test/flutter_test.dart';
import 'package:food_diary/support/format.dart';

void main() {
  final sekarang = DateTime(2026, 11, 1, 14, 5);

  test('labelHari', () {
    expect(labelHari(DateTime(2026, 11, 1, 7), sekarang), 'Hari Ini');
    expect(labelHari(DateTime(2026, 10, 31, 23), sekarang), 'Kemarin');
    expect(labelHari(DateTime(2026, 10, 30), sekarang), '30 Oktober 2026');
  });

  test('formatJam', () {
    expect(formatJam(DateTime(2026, 11, 1, 7, 5)), '07:05');
    expect(formatJam(DateTime(2026, 11, 1, 13, 45)), '13:45');
  });

  test('rentangJam', () {
    expect(rentangJam([]), '');
    expect(rentangJam([DateTime(2026, 11, 1, 7, 30)]), '07:30');
    expect(
      rentangJam([DateTime(2026, 11, 1, 3, 36), DateTime(2026, 11, 1, 1, 36)]),
      '01:36–03:36',
    );
  });

  test('tanggalSama', () {
    expect(
      tanggalSama(DateTime(2026, 11, 1, 1), DateTime(2026, 11, 1, 23)),
      isTrue,
    );
    expect(tanggalSama(DateTime(2026, 11, 1), DateTime(2026, 11, 2)), isFalse);
  });
}
