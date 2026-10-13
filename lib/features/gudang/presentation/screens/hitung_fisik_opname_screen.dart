import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/offline/offline_providers.dart';
import '../../../../core/offline/offline_queue.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../data/models/stock_opname_model.dart';
import '../../data/repositories/persediaan_repository.dart';

/// Layar input hitung fisik untuk satu sesi stock opname ([opname]).
class HitungFisikOpnameScreen extends StatefulWidget {
  final StokOpnameSesiModel opname;

  /// Membuat layar hitung fisik untuk sesi [opname].
  const HitungFisikOpnameScreen({super.key, required this.opname});

  /// Membuat state layar hitung fisik.
  @override
  State<HitungFisikOpnameScreen> createState() => _HitungFisikOpnameScreenState();
}

/// State layar hitung fisik; mengelola controller jumlah fisik per detail dan status penyimpanan.
class _HitungFisikOpnameScreenState extends State<HitungFisikOpnameScreen> {
  final Map<int, TextEditingController> _controllers = {};
  bool _isSaving = false;

  /// Menyiapkan satu controller input per detail opname, diisi jumlah fisik yang sudah ada.
  @override
  void initState() {
    super.initState();
    for (final d in widget.opname.details) {
      _controllers[d.id] = TextEditingController(
        text: d.jumlahFisik != null ? d.jumlahFisik.toString() : '',
      );
    }
  }

  /// Membuang semua controller input agar tidak bocor memori.
  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Mengirim hasil hitung fisik; [finalisasi] `true` mengunci sesi dan menerbitkannya ke otorisasi, `false` hanya simpan sementara.
  Future<void> _submitCount(bool finalisasi) async {
    setState(() => _isSaving = true);
    final List<Map<String, dynamic>> items = [];
    for (final d in widget.opname.details) {
      final text = _controllers[d.id]?.text.trim() ?? '';
      final fisik = int.tryParse(text) ?? 0;
      items.add({
        'detail_id': d.id,
        'jumlah_fisik': fisik,
        'catatan': d.catatan,
      });
    }

    try {
      final container = ProviderScope.containerOf(context, listen: false);
      await container.read(persediaanRepositoryProvider).simpanHitungFisik(
            opnameId: widget.opname.id,
            items: items,
            finalisasi: finalisasi,
          );

      if (!mounted) return;
      AppToast.success(context, finalisasi
          ? 'Sesi opname telah difinalisasi dan diterbitkan ke otorisasi penyesuaian.'
          : 'Hasil hitung fisik berhasil disimpan sementara.');
      Navigator.pop(context, true);
    } catch (e) {
      if (e is ApiException && e.isNetworkError) {
        final container = ProviderScope.containerOf(context, listen: false);
        await container.read(offlineQueueCountProvider.notifier).enqueue(
          OfflineMutation.jenisHitungFisik,
          {
            'opname_id': widget.opname.id,
            'items': items,
            'finalisasi': finalisasi,
          },
        );
        if (!mounted) return;
        AppToast.info(context, 'Tidak ada koneksi. Disimpan, akan dikirim otomatis saat online.');
        Navigator.pop(context, true);
        return;
      }
      if (!mounted) return;
      setState(() => _isSaving = false);
      AppToast.error(context, e.toString());
    }
  }

  /// Menyusun UI hitung fisik: daftar detail batch dengan input jumlah fisik serta tombol simpan sementara/finalisasi.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text('Hitung: ${widget.opname.kode}'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.surface,
              child: const Row(
                children: [
                  Icon(LucideIcons.info, size: 16, color: AppColors.tintBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Masukkan jumlah fisik riil di rak untuk setiap batch komoditas.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.border, height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: widget.opname.details.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final d = widget.opname.details[idx];
                  final controller = _controllers[d.id]!;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Batch: ${d.nomorBatch}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                  color: AppColors.primaryPurple,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Rak: ${d.lokasiRak}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.namaBarang,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSecondary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Buku: ${d.jumlahSistem} ${d.satuan}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Fisik Riil (${d.satuan})',
                                  hintText: '0',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom Sticky Bar - Full Width White Background
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => _submitCount(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Simpan Draf'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Finalisasi Sesi',
                          isLoading: _isSaving,
                          onPressed: () => _submitCount(true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
