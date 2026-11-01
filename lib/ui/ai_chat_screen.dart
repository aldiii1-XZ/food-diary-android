import 'package:flutter/material.dart';

import '../ai/ai_client.dart';

/// Tanya-jawab seputar makanan. Riwayat obrolan hanya di memori —
/// ditutup, mulai dari awal lagi.
class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key, this.client});

  /// Bisa diisi klien palsu saat pengujian.
  final AiClient? client;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _Pesan {
  _Pesan(this.teks, {this.dariAku = false, this.gagal = false});

  final String teks;
  final bool dariAku;
  final bool gagal;
}

class _AiChatScreenState extends State<AiChatScreen> {
  late final AiClient _ai = widget.client ?? AiClient();
  final _kendali = TextEditingController();
  final _gulir = ScrollController();
  final List<_Pesan> _pesan = [];
  bool _menunggu = false;

  static const _saran = [
    'Ide menu sarapan yang mengenyangkan',
    'Kalori nasi goreng seporsi?',
    'Camilan malam yang tidak bikin berat',
  ];

  @override
  void dispose() {
    _kendali.dispose();
    _gulir.dispose();
    super.dispose();
  }

  void _keBawah() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_gulir.hasClients) return;
      _gulir.animateTo(
        _gulir.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _kirim([String? teksSiap]) async {
    final teks = (teksSiap ?? _kendali.text).trim();
    if (teks.isEmpty || _menunggu) return;
    _kendali.clear();
    setState(() {
      _pesan.add(_Pesan(teks, dariAku: true));
      _menunggu = true;
    });
    _keBawah();

    final riwayat = <Map<String, dynamic>>[
      for (final p in _pesan)
        if (!p.gagal) {'role': p.dariAku ? 'user' : 'assistant', 'content': p.teks},
    ];
    final potong = riwayat.length > 12
        ? riwayat.sublist(riwayat.length - 12)
        : riwayat;

    try {
      final jawab = await _ai.tanya(potong);
      if (!mounted) return;
      setState(() {
        _pesan.add(_Pesan(jawab));
        _menunggu = false;
      });
    } on AiError catch (e) {
      if (!mounted) return;
      setState(() {
        _pesan.add(_Pesan(e.pesan, gagal: true));
        _menunggu = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _pesan.add(_Pesan('Ada yang salah: $e', gagal: true));
        _menunggu = false;
      });
    }
    _keBawah();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Text('Asisten makanan', style: theme.textTheme.titleLarge),
        ),
        Expanded(
          child: _pesan.isEmpty && !_menunggu
              ? _kosong(theme)
              : ListView.builder(
                  controller: _gulir,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  itemCount: _pesan.length + (_menunggu ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _pesan.length) {
                      return _gelembung(
                        theme,
                        _Pesan('Sedang menyusun jawaban...'),
                      );
                    }
                    return _gelembung(theme, _pesan[i]);
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _kendali,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _kirim(),
                  decoration: InputDecoration(
                    hintText: 'Tulis pertanyaan...',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _menunggu ? null : () => _kirim(),
                icon: const Icon(Icons.send),
                tooltip: 'Kirim',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _kosong(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tanya apa saja soal makanan',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'Kalori, ide menu, atau isi piringmu. Jawaban berasal dari AI — '
            'pakai sebagai perkiraan saja.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _saran)
                ActionChip(
                  label: Text(s),
                  onPressed: _menunggu ? null : () => _kirim(s),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _gelembung(ThemeData theme, _Pesan p) {
    final scheme = theme.colorScheme;
    final aku = p.dariAku;
    final warna = p.gagal
        ? scheme.errorContainer
        : aku
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest;
    final teksWarna = p.gagal
        ? scheme.onErrorContainer
        : aku
            ? scheme.onPrimaryContainer
            : scheme.onSurface;
    return Align(
      alignment: aku ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.85,
        ),
        decoration: BoxDecoration(
          color: warna,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(p.teks, style: TextStyle(color: teksWarna, height: 1.35)),
      ),
    );
  }
}
