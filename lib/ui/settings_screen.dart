import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'today_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            const ScreenHeader(
              title: 'Pengaturan',
              subtitle: 'Tentang aplikasi & data.',
            ),
            ListTile(
              leading: Icon(Icons.restaurant_outlined, color: scheme.primary),
              title: const Text('Food Diary'),
              subtitle: const Text('Versi 0.1.0'),
            ),
            Divider(
              height: 1,
              thickness: 0.5,
              indent: 20,
              endIndent: 20,
              color: scheme.outlineVariant,
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined,
                  color: scheme.primary),
              title: const Text('Jumlah catatan'),
              trailing: Text(
                '${state.entries.length}',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Text(
                'Semua catatan dan foto tersimpan di perangkat ini. '
                'Tidak ada akun, iklan, atau data yang dikirim ke mana pun.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        );
      },
    );
  }
}
