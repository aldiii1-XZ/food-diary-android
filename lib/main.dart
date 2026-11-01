import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'state/app_state.dart';
import 'storage/store_io.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final base = await getApplicationDocumentsDirectory();
  final store = FileEntryStore(Directory('${base.path}/food_diary'));
  runApp(FoodDiaryApp(state: AppState(store)));
}
