import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'state/app_state.dart';
import 'ui/home_shell.dart';
import 'ui/theme.dart';

class FoodDiaryApp extends StatefulWidget {
  const FoodDiaryApp({super.key, required this.state});

  final AppState state;

  @override
  State<FoodDiaryApp> createState() => _FoodDiaryAppState();
}

class _FoodDiaryAppState extends State<FoodDiaryApp> {
  @override
  void initState() {
    super.initState();
    widget.state.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Diary',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      locale: const Locale('id'),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: HomeShell(state: widget.state),
    );
  }
}
