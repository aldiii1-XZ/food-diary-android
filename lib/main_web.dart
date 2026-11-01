import 'package:flutter/material.dart';

import 'app.dart';
import 'state/app_state.dart';
import 'storage/store_web.dart';

/// Titik masuk build web (Vercel): data tersimpan di browser ini.
/// Jalankan dengan: flutter run -d chrome -t lib/main_web.dart
void main() {
  // ?semantics=1 memaksa mode aksesibilitas (untuk uji otomatis / pembaca layar).
  if (Uri.base.queryParameters.containsKey('semantics')) {
    WidgetsFlutterBinding.ensureInitialized();
    WidgetsBinding.instance.ensureSemantics();
  }
  runApp(FoodDiaryApp(state: AppState(WebEntryStore())));
}
