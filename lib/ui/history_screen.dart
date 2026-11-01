import 'package:flutter/material.dart';

import '../models/food_entry.dart';
import '../state/app_state.dart';
import '../support/format.dart';
import 'entry_detail_screen.dart';
import 'today_screen.dart';
import 'widgets/empty_state.dart';
import 'widgets/entry_tile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final entries = state.entries;
        final sekarang = DateTime.now();
        final grup = <String, List<FoodEntry>>{};
        for (final e in entries) {
          (grup[labelHari(e.consumedAt, sekarang)] ??= []).add(e);
        }

        final anak = <Widget>[
          ScreenHeader(
            title: 'Riwayat',
            subtitle: entries.isEmpty
                ? 'Semua catatanmu muncul di sini.'
                : '${entries.length} catatan tersimpan.',
          ),
        ];
        grup.forEach((label, items) {
          anak.add(Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
            child: Text(
              label,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ));
          for (var i = 0; i < items.length; i++) {
            final e = items[i];
            anak.add(EntryTile(
              entry: e,
              state: state,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EntryDetailScreen(state: state, entry: e),
                ),
              ),
            ));
            if (i < items.length - 1) {
              anak.add(Divider(
                height: 1,
                thickness: 0.5,
                indent: 90,
                endIndent: 20,
                color: scheme.outlineVariant,
              ));
            }
          }
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: entries.isEmpty
                  ? const EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'Belum ada catatan',
                      message:
                          'Catatan yang kamu simpan akan dikelompokkan per hari di sini.',
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: anak,
                    ),
            ),
          ],
        );
      },
    );
  }
}
