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
    expect(find.text('Kalori (kkal, opsional)'), findsOneWidget);

    // kolom kalori menambah tinggi form; "Simpan" perlu digulir dulu
    await tester.scrollUntilVisible(
      find.text('Simpan'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
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

  testWidgets('kartu kalori: total hari ini dan sisa dari batas',
      (tester) async {
    final state = AppState(MemoryEntryStore([
      FoodEntry(
        id: '1',
        name: 'Nasi goreng',
        note: '',
        kcal: 650,
        consumedAt: DateTime.now(),
      ),
      FoodEntry(
        id: '2',
        name: 'Telur rebus',
        note: '2 butir · 140 kkal',
        consumedAt: DateTime.now(),
      ),
    ]));
    await state.init();
    await state.simpanBatasKalori(2000);

    await tester.pumpWidget(FoodDiaryApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('790 kkal'), findsOneWidget); // 650 + 140
    expect(find.text('dari 2.000 kkal'), findsOneWidget);
    expect(find.text('Sisa 1.210 kkal'), findsOneWidget);
  });

  testWidgets('kartu kalori: lewat batas diberi tanda', (tester) async {
    final state = AppState(MemoryEntryStore([
      FoodEntry(
        id: '1',
        name: 'Sepiring besar',
        note: '',
        kcal: 2200,
        consumedAt: DateTime.now(),
      ),
    ]));
    await state.init();
    await state.simpanBatasKalori(2000);

    await tester.pumpWidget(FoodDiaryApp(state: state));
    await tester.pumpAndSettle();

    expect(find.text('Lewat batas'), findsOneWidget);
    expect(find.text('Lewat 200 kkal'), findsOneWidget);
  });

  testWidgets('kartu kalori: ketuk -> atur batas -> simpan, lalu hapus',
      (tester) async {
    final state = AppState(MemoryEntryStore([
      FoodEntry(
        id: '1',
        name: 'Nasi goreng',
        note: '',
        kcal: 650,
        consumedAt: DateTime.now(),
      ),
    ]));
    await state.init();

    await tester.pumpWidget(FoodDiaryApp(state: state));
    await tester.pumpAndSettle();
    expect(find.text('batas belum diatur'), findsOneWidget);

    await tester.tap(find.text('Kalori hari ini'));
    await tester.pumpAndSettle();
    expect(find.text('Batas kalori harian'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '1800');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(state.batasKalori, 1800);
    expect(find.text('dari 1.800 kkal'), findsOneWidget);

    await tester.tap(find.text('Kalori hari ini'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus batas'));
    await tester.pumpAndSettle();

    expect(state.batasKalori, isNull);
    expect(find.text('batas belum diatur'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
