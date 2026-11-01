import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../ai/ai_client.dart';
import '../models/food_entry.dart';
import '../state/app_state.dart';
import '../support/format.dart';
import '../support/pilih_foto.dart';
import 'widgets/entry_photo.dart';

/// Halaman catatan: untuk menambah (baru) atau melihat/mengubah (lama).
class EntryDetailScreen extends StatefulWidget {
  const EntryDetailScreen({
    super.key,
    required this.state,
    this.entry,
    this.photoBytes,
    this.photoExtension,
  });

  factory EntryDetailScreen.newEntry({
    required AppState state,
    required Uint8List photoBytes,
    required String photoExtension,
  }) =>
      EntryDetailScreen(
        state: state,
        photoBytes: photoBytes,
        photoExtension: photoExtension,
      );

  final AppState state;

  /// null = catatan baru.
  final FoodEntry? entry;
  final Uint8List? photoBytes;
  final String? photoExtension;

  bool get isBaru => entry == null;

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  late final TextEditingController _nama;
  late final TextEditingController _catatan;
  late final TextEditingController _kalori;
  late DateTime _waktu;
  Uint8List? _fotoBaru;
  String? _extBaru;
  bool _menyimpan = false;
  bool _kenali = false;
  final AiClient _ai = AiClient();

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _nama = TextEditingController(text: e?.name ?? '');
    _catatan = TextEditingController(text: e?.note ?? '');
    _kalori = TextEditingController(text: e?.kcal?.toString() ?? '');
    _waktu = e?.consumedAt ?? DateTime.now();
    _fotoBaru = widget.photoBytes;
    _extBaru = widget.photoExtension;
    if (widget.isBaru && _fotoBaru != null) {
      // Kenali otomatis begitu form terbuka; kalau gagal, diam saja.
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _kenaliFoto(otomatis: true));
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _catatan.dispose();
    _kalori.dispose();
    super.dispose();
  }

  String? get _pathFotoLama {
    final nama = widget.entry?.photoFileName;
    if (nama == null || nama.isEmpty) return null;
    final path = widget.state.store.photoPath(nama);
    return path.isEmpty ? null : path;
  }

  Future<void> _pilihTanggal() async {
    final hasil = await showDatePicker(
      context: context,
      initialDate: _waktu,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (hasil == null) return;
    setState(() {
      _waktu = DateTime(hasil.year, hasil.month, hasil.day, _waktu.hour,
          _waktu.minute);
    });
  }

  Future<void> _pilihJam() async {
    final hasil = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_waktu),
    );
    if (hasil == null) return;
    setState(() {
      _waktu = DateTime(
          _waktu.year, _waktu.month, _waktu.day, hasil.hour, hasil.minute);
    });
  }

  Future<void> _gantiFoto() async {
    try {
      final hasil = await pilihFoto(context);
      if (hasil == null || !mounted) return;
      setState(() {
        _fotoBaru = hasil.bytes;
        _extBaru = hasil.extension;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Tidak bisa mengambil foto: $e')));
    }
  }

  String? _extLama() {
    final n = widget.entry?.photoFileName;
    if (n == null || !n.contains('.')) return null;
    return n.split('.').last;
  }

  String _mime(String? ext) => switch (ext?.toLowerCase()) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };

  /// Kirim foto ke AI lalu isi kolom nama (dan catatan bila masih kosong).
  Future<void> _kenaliFoto({bool otomatis = false}) async {
    if (_kenali) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _kenali = true);
    try {
      final bytes = _fotoBaru ?? await bacaBytesFoto(_pathFotoLama);
      if (bytes == null || bytes.isEmpty) {
        throw AiError('Belum ada foto untuk dikenali');
      }
      final hasil =
          await _ai.kenaliFoto(bytes, mime: _mime(_extBaru ?? _extLama()));
      if (!mounted) return;
      setState(() {
        _kenali = false;
        if (hasil.nama.isNotEmpty) _nama.text = hasil.nama;
        final angkaKalori = hasil.kalori.replaceAll(RegExp(r'[^0-9]'), '');
        if (angkaKalori.isNotEmpty && _kalori.text.trim().isEmpty) {
          _kalori.text = angkaKalori;
        }
        final ringkas = hasil.ringkasan;
        if (ringkas.isNotEmpty && _catatan.text.trim().isEmpty) {
          _catatan.text = ringkas;
        }
      });
      if (!otomatis) {
        messenger.showSnackBar(const SnackBar(content: Text('Foto dikenali')));
      }
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _kenali = false);
      if (!otomatis) {
        messenger
            .showSnackBar(SnackBar(content: Text('Gagal mengenali foto: $e')));
      }
    }
  }

  Future<void> _simpan() async {
    if (_menyimpan) return;
    setState(() => _menyimpan = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final kcal = int.tryParse(_kalori.text.trim());
    try {
      if (widget.isBaru) {
        final bytes = _fotoBaru;
        if (bytes == null) throw StateError('foto belum ada');
        await widget.state.createEntry(
          photoBytes: bytes,
          photoExtension: _extBaru ?? 'jpg',
          name: _nama.text,
          note: _catatan.text,
          kcal: kcal,
          consumedAt: _waktu,
        );
      } else {
        await widget.state.updateEntry(
          widget.entry!.id,
          name: _nama.text,
          note: _catatan.text,
          newKcal: kcal,
          gantiKcal: true,
          consumedAt: _waktu,
          newPhotoBytes: _fotoBaru == widget.photoBytes ? null : _fotoBaru,
          newPhotoExtension: _extBaru,
        );
      }
      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(widget.isBaru ? 'Catatan disimpan' : 'Perubahan disimpan'),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  Future<void> _hapus() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus catatan ini?'),
        content: const Text(
            'Foto dan catatannya ikut terhapus dan tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Hapus',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (konfirmasi != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await widget.state.deleteEntry(widget.entry!.id);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Catatan dihapus')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final adaFoto = _fotoBaru != null || _pathFotoLama != null;
    return Scaffold(
      appBar: AppBar(title: Text(widget.isBaru ? 'Catatan Baru' : 'Catatan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            if (_fotoBaru != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _fotoBaru!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              )
            else
              EntryPhoto(
                path: _pathFotoLama,
                width: double.infinity,
                height: 220,
                borderRadius: 12,
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 4,
                children: [
                  TextButton.icon(
                    onPressed: _menyimpan ? null : _gantiFoto,
                    icon: const Icon(Icons.photo_outlined, size: 18),
                    label: Text(adaFoto ? 'Ganti foto' : 'Tambah foto'),
                  ),
                  if (adaFoto)
                    TextButton.icon(
                      onPressed: (_menyimpan || _kenali)
                          ? null
                          : () => _kenaliFoto(),
                      icon: _kenali
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search, size: 18),
                      label: Text(
                        _kenali ? 'Mengenali...' : 'Kenali dari foto',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nama,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nama makanan',
                hintText: 'mis. Nasi goreng',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _catatan,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
                hintText: 'mis. porsi, tempat, perasaan',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _kalori,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Kalori (kkal, opsional)',
                hintText: 'mis. 650',
                helperText: 'Terisi sendiri saat kenali foto.',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _KotakKetuk(
                    label: 'Tanggal',
                    nilai: formatTanggal(_waktu),
                    onTap: _menyimpan ? null : _pilihTanggal,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KotakKetuk(
                    label: 'Jam',
                    nilai: formatJam(_waktu),
                    onTap: _menyimpan ? null : _pilihJam,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _menyimpan ? null : _simpan,
              child: Text(_menyimpan ? 'Menyimpan…' : 'Simpan'),
            ),
            if (!widget.isBaru) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: _menyimpan ? null : _hapus,
                child: Text(
                  'Hapus catatan',
                  style: TextStyle(color: scheme.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _KotakKetuk extends StatelessWidget {
  const _KotakKetuk({
    required this.label,
    required this.nilai,
    required this.onTap,
  });

  final String label;
  final String nilai;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(nilai, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
