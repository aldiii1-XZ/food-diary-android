import 'package:flutter/material.dart';

import 'app.dart';
import 'demo/demo_seed.dart';
import 'state/app_state.dart';
import 'storage/store_memory.dart';

/// Halaman pratinjau: data contoh di memori, tanpa menyentuh file.
/// Jalankan dengan: flutter run -t lib/main_demo.dart
/// (atau flutter build web -t lib/main_demo.dart untuk pratinjau browser)
void main() {
  runApp(
    FoodDiaryApp(
      state: AppState(MemoryEntryStore(demoEntries(DateTime.now()))),
    ),
  );
}
