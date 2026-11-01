import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/app_state.dart';
import '../../support/format.dart';
import '../../support/kalori.dart';

/// Kartu ringkasan kalori hari ini + pengatur batas harian.
///
/// Ketuk untuk mengatur/mengubah batas; ketuk "Hapus batas" untuk mematikan
/// hitungan batas tanpa menghapus catatan.
class KartuKalori extends StatelessWidget {
  const KartuKalori({super.key, required this.state});

  final AppState state;

  Future<void> _aturBatas(BuildContext context) async {
    // Tanpa TextEditingController: controller yang di-dispose begitu dialog
    // ditutup masih dipakai saat animasi penutup berjalan.
    var teks = state.batasKalori?.toString() ?? '';
    final aksi = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batas kalori harian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dipakai untuk menghitung sisa kalori hari ini.'),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: teks,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Batas harian (kkal)',
                hintText: 'mis. 2000',
              ),
              onChanged: (v) => teks = v,
              onFieldSubmitted: (_) => Navigator.pop(ctx, 'simpan'),
            ),
          ],
        ),
        actions: [
          if (state.batasKalori != null)
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'hapus'),
              child: const Text('Hapus batas'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'simpan'),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    final angka = teks.trim();
    if (aksi == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (aksi == 'hapus') {
        await state.simpanBatasKalori(null);
        messenger.showSnackBar(
            const SnackBar(content: Text('Batas kalori dihapus')));
        return;
      }
      final nilai = int.tryParse(angka);
      if (nilai == null || nilai <= 0) {
        messenger.showSnackBar(
            const SnackBar(content: Text('Isi angka lebih dari 0')));
        return;
      }
      await state.simpanBatasKalori(nilai);
      messenger.showSnackBar(
          SnackBar(content: Text('Batas harian: ${formatRibuan(nilai)} kkal')));
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text('Gagal menyimpan batas: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = state.ringkasanHariIni;
    final lewat = r.lewatBatas;
    final warna = lewat ? scheme.error : scheme.primary;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: InkWell(
        onTap: () => _aturBatas(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department_outlined,
                      size: 18, color: warna),
                  const SizedBox(width: 6),
                  Text(
                    'Kalori hari ini',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  if (lewat)
                    Text(
                      'Lewat batas',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${formatRibuan(r.total)} kkal',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: lewat ? scheme.error : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    r.adaBatas
                        ? 'dari ${formatRibuan(r.batas!)} kkal'
                        : 'batas belum diatur',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
              if (r.adaBatas) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  // Indikator dekoratif: jangan ambil alih semantik kartu.
                  // Tanpa ini, pembaca layar/tap menangkapnya sebagai
                  // progressbar (bukan tombol), sehingga kartu tak bisa dibuka.
                  child: ExcludeSemantics(
                    child: LinearProgressIndicator(
                      value: r.progres,
                      minHeight: 6,
                      color: warna,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                _barisBawah(r),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: lewat ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _barisBawah(RingkasanKalori r) {
    final bagian = <String>[
      if (r.adaBatas)
        (r.sisa! >= 0
            ? 'Sisa ${formatRibuan(r.sisa!)} kkal'
            : 'Lewat ${formatRibuan(-r.sisa!)} kkal')
      else
        'Ketuk untuk mengatur batas kalori harian.',
      if (r.tanpaAngka > 0) '${r.tanpaAngka} catatan belum ada angka kalori',
    ];
    return bagian.join(' · ');
  }
}
