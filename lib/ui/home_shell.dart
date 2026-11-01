import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../support/pilih_foto.dart';
import 'entry_detail_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'today_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.state});

  final AppState state;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  Future<void> _mulaiCatat() async {
    try {
      final hasil = await pilihFoto(context);
      if (hasil == null || !mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EntryDetailScreen.newEntry(
            state: widget.state,
            photoBytes: hasil.bytes,
            photoExtension: hasil.extension,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Tidak bisa mengambil foto: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: switch (_tab) {
          0 => TodayScreen(state: widget.state),
          1 => HistoryScreen(state: widget.state),
          _ => SettingsScreen(state: widget.state),
        },
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton(
              onPressed: _mulaiCatat,
              tooltip: 'Catat makan',
              child: const Icon(Icons.photo_camera_outlined),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule),
            label: 'Hari Ini',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }
}
