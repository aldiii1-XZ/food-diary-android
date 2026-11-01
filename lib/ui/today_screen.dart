import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../support/format.dart';
import 'entry_detail_screen.dart';
import 'widgets/empty_state.dart';
import 'widgets/entry_tile.dart';
import 'widgets/kartu_kalori.dart';

/// Judul halaman + satu baris keterangan.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.loadError != null) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Catatan tidak bisa dibuka',
            message: state.loadError!,
          );
        }
        final entries = state.todayEntries;
        final keterangan = entries.isEmpty
            ? formatTanggal(DateTime.now())
            : '${formatTanggal(DateTime.now())} · ${entries.length} catatan · '
                '${rentangJam([for (final e in entries) e.consumedAt])}';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'Hari Ini', subtitle: keterangan),
            KartuKalori(state: state),
            Expanded(
              child: entries.isEmpty
                  ? const EmptyState(
                      icon: Icons.photo_camera_outlined,
                      title: 'Belum ada catatan hari ini',
                      message:
                          'Tekan tombol kamera untuk mencatat makanan pertamamu.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        thickness: 0.5,
                        indent: 90,
                        endIndent: 20,
                        color: scheme.outlineVariant,
                      ),
                      itemBuilder: (context, i) => EntryTile(
                        entry: entries[i],
                        state: state,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EntryDetailScreen(
                              state: state,
                              entry: entries[i],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}
