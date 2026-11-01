import 'package:flutter/material.dart';

import '../../models/food_entry.dart';
import '../../state/app_state.dart';
import '../../support/format.dart';
import 'entry_photo.dart';

/// Satu baris catatan di daftar.
class EntryTile extends StatelessWidget {
  const EntryTile({
    super.key,
    required this.entry,
    required this.state,
    required this.onTap,
  });

  final FoodEntry entry;
  final AppState state;
  final VoidCallback onTap;

  String? get _photoPath {
    final nama = entry.photoFileName;
    if (nama == null || nama.isEmpty) return null;
    final path = state.store.photoPath(nama);
    return path.isEmpty ? null : path;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final judul = entry.name.isEmpty ? 'Tanpa nama' : entry.name;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            EntryPhoto(path: _photoPath, width: 56, height: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    judul,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      entry.note,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatJam(entry.consumedAt),
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            Icon(Icons.chevron_right, size: 20, color: scheme.outline),
          ],
        ),
      ),
    );
  }
}
