import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../../../shared/widgets/app_quantity_stepper.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../data/models/amprah_model.dart';
import '../providers/distribusi_provider.dart';

/// Bottom sheet keputusan amprah (setujui/tolak) untuk Meja 1 (Karu) dan Meja 2 (gudang); alasan wajib saat tolak.
class AmprahApprovalModal extends ConsumerStatefulWidget {
  final AmprahHeaderModel amprah;
  final bool isSetujui;

  const AmprahApprovalModal({
    super.key,
    required this.amprah,
    required this.isSetujui,
  });

  /// Menampilkan modal keputusan untuk [amprah]; menutup dengan true bila aksi berhasil.
  static Future<bool?> show(
    BuildContext context, {
    required AmprahHeaderModel amprah,
    required bool isSetujui,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AmprahApprovalModal(amprah: amprah, isSetujui: isSetujui),
    );
  }

  /// Membuat state modal keputusan amprah.
  @override
  ConsumerState<AmprahApprovalModal> createState() => _AmprahApprovalModalState();
}

/// State modal: menyimpan controller catatan dan menjalankan keputusan amprah.
class _AmprahApprovalModalState extends ConsumerState<AmprahApprovalModal> {
  final TextEditingController _noteController = TextEditingController();
  late final Map<int, int> _quotas;

  @override
  void initState() {
    super.initState();
    _quotas = {
      for (final item in widget.amprah.items)
        item.id: item.jumlahDisetujui > 0 ? item.jumlahDisetujui : item.jumlahDiminta,
    };
  }

  /// Membersihkan controller catatan agar tidak bocor memori.
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// Memvalidasi alasan tolak (wajib) atau kuota Meja 2, lalu mengirim keputusan dan menutup modal bila berhasil.
  Future<void> _kirim(BuildContext context) async {
    final catatan = _noteController.text.trim();
    if (!widget.isSetujui && catatan.isEmpty) {
      AppToast.error(context, 'Alasan penolakan wajib diisi!');
      return;
    }

    List<Map<String, int>>? itemsPayload;
    if (widget.isSetujui && widget.amprah.isDisetujuiKaru) {
      final allZero = _quotas.values.isNotEmpty && _quotas.values.every((q) => q == 0);
      if (allZero) {
        AppToast.error(context, 'Minimal satu barang harus disetujui, atau gunakan Tolak.');
        return;
      }
      itemsPayload = [
        for (final item in widget.amprah.items)
          {
            'id': item.id,
            'jumlah_disetujui': _quotas[item.id] ??
                (item.jumlahDisetujui > 0 ? item.jumlahDisetujui : item.jumlahDiminta),
          },
      ];
    }

    final ok = await ref.read(amprahActionProvider.notifier).approveAmprah(
          id: widget.amprah.id,
          isSetujui: widget.isSetujui,
          catatan: catatan.isNotEmpty ? catatan : null,
          items: itemsPayload,
        );
    if (!context.mounted) return;
    final state = ref.read(amprahActionProvider);
    if (ok) {
      AppToast.success(context, state.successMessage ?? 'Berhasil');
      Navigator.pop(context, true);
    } else {
      AppToast.error(context, state.errorMessage ?? 'Gagal');
    }
  }

  /// Menyusun UI modal: judul, warna, label tombol sesuai aksi, input catatan, dan tombol eksekusi.
  @override
  Widget build(BuildContext context) {
    final isSetujui = widget.isSetujui;
    final Color themeColor = isSetujui ? AppColors.success : AppColors.danger;
    final IconData icon = isSetujui ? LucideIcons.checkCheck : LucideIcons.alertTriangle;
    final String modalTitle = isSetujui ? 'Setujui Amprah' : 'Tolak Amprah';
    final String buttonLabel = isSetujui ? 'Ya, Setujui' : 'Ya, Tolak';

    return AppBottomSheetWrapper(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: themeColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modalTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.amprah.kode} • ${widget.amprah.unit}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isSetujui && widget.amprah.isDisetujuiKaru) ...[
            const Text(
              'Alokasi Kuota Persetujuan Gudang:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.35,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.amprah.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = widget.amprah.items[index];
                  final quota = _quotas[item.id] ?? item.jumlahDiminta;
                  final isBackorder = quota > item.stokTersedia;
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.namaBarang,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Diminta: ${item.jumlahDiminta} ${item.satuan} • Stok Gudang: ${item.stokTersedia} ${item.satuan}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppQuantityStepper(
                              min: 0,
                              max: item.jumlahDiminta,
                              value: quota,
                              onChanged: (val) {
                                setState(() {
                                  _quotas[item.id] = val;
                                });
                              },
                            ),
                          ],
                        ),
                        if (isBackorder) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(LucideIcons.alertCircle, size: 13, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  'Kuota melebihi stok gudang (${quota - item.stokTersedia} ${item.satuan} selisih dicatat sebagai backorder)',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: isSetujui
                  ? 'Catatan persetujuan (opsional)...'
                  : 'Alasan penolakan amprah (wajib)...',
              filled: true,
              fillColor: AppColors.canvas,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: buttonLabel,
            backgroundColor: themeColor,
            textColor: Colors.white,
            onPressed: () => _kirim(context),
          ),
        ],
      ),
    );
  }
}
