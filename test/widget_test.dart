import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_diary/app.dart';
import 'package:food_diary/models/food_entry.dart';
import 'package:food_diary/state/app_state.dart';
import 'package:food_diary/storage/store_memory.dart';

Future<void> bukaApp(WidgetTester tester, List<FoodEntry> entries) async {
  await tester.pumpWidget(
    FoodDiaryApp(state: AppState(MemoryEntryStore(entries))),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tanpa catatan: tampil ajakan mencatat', (tester) async {
    await bukaApp(tester, []);
    expect(find.text('Belum ada catatan hari ini'), findsOneWidget);
  });

  testWidgets('catatan hari ini tampil di tab Hari Ini', (tester) async {
    final sekarang = DateTime.now();
    await bukaApp(tester, [
      FoodEntry(
        id: '1',
        name: 'Kopi susu',
        note: 'tanpa gula',
        consumedAt: sekarang.subtract(const Duration(hours: 2)),
      ),
      FoodEntry(
        id: '2',
        name: 'Mie ayam',
        note: '',
        consumedAt: sekarang.subtract(const Duration(hours: 1)),
      ),
    ]);

    expect(find.text('Kopi susu'), findsOneWidget);
    expect(find.text('Mie ayam'), findsOneWidget);
  });

  testWidgets('ketuk catatan: halaman ubah terbuka lalu bisa dihapus',
      (tester) async {
    final sekarang = DateTime.now();
    await bukaApp(tester, [
      FoodEntry(
        id: '1',
        name: 'Kopi susu',
        note: '',
        consumedAt: sekarang.subtract(const Duration(minutes: 30)),
      ),
    ]);

    await tester.tap(find.text('Kopi susu'));
    await tester.pumpAndSettle();
    expect(find.text('Catatan'), findsOneWidget);
    expect(find.text('Simpan'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Hapus catatan'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus catatan'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus catatan ini?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Hapus'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada catatan hari ini'), findsOneWidget);
    // biarkan SnackBar selesai supaya tidak ada timer tersisa
    await tester.pump(const Duration(seconds: 5));
  });
}
