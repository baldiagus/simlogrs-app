import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../providers/aset_provider.dart';

class ModalPengembalianAsetSheet extends ConsumerStatefulWidget {
  final int peminjamanId;
  final int detailId;
  final int asetId;
  final String kodeDokumen;
  final String namaBarang;
  final VoidCallback? onSuccess;

  const ModalPengembalianAsetSheet({
    super.key,
    required this.peminjamanId,
    required this.detailId,
    required this.asetId,
    required this.kodeDokumen,
    required this.namaBarang,
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required int peminjamanId,
    required int detailId,
    required int asetId,
    required String kodeDokumen,
    required String namaBarang,
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalPengembalianAsetSheet(
        peminjamanId: peminjamanId,
        detailId: detailId,
        asetId: asetId,
        kodeDokumen: kodeDokumen,
        namaBarang: namaBarang,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<ModalPengembalianAsetSheet> createState() =>
      _ModalPengembalianAsetSheetState();
}

class _ModalPengembalianAsetSheetState
    extends ConsumerState<ModalPengembalianAsetSheet> {
  String _kondisi = 'BAIK';
  final TextEditingController _catatanController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Widget _buildKondisiChip(String val, String label) {
    final isSelected = _kondisi == val;
    Color color = AppColors.success;
    if (val == 'RUSAK_RINGAN') color = AppColors.warning;
    if (val == 'RUSAK_BERAT') color = AppColors.danger;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _kondisi = val),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final navigator = Navigator.of(context);

    final notifier = ref.read(asetActionProvider.notifier);
    final ok = await notifier.konfirmasiPengembalian(
      peminjamanId: widget.peminjamanId,
      inspeksi: [
        {
          'permintaan_peminjaman_detail_id': widget.detailId,
          'aset_id': widget.asetId,
          'kondisi_saat_kembali': _kondisi,
          'catatan': _catatanController.text.trim(),
        }
      ],
      catatan: _catatanController.text.trim(),
    );

    if (!mounted) return;
    final state = ref.read(asetActionProvider);
    if (ok) {
      AppToast.success(context, state.successMessage ?? 'Pengembalian aset berhasil diproses.');
    } else {
      AppToast.error(context, state.errorMessage ?? 'Gagal memproses pengembalian.');
    }
    navigator.pop();

    if (ok) {
      widget.onSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetWrapper(
      title: 'Inspeksi Fisik Pengembalian',
      subtitle: '${widget.kodeDokumen} • ${widget.namaBarang}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Kondisi Fisik Saat Kembali:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildKondisiChip('BAIK', 'Baik'),
              const SizedBox(width: 8),
              _buildKondisiChip('RUSAK_RINGAN', 'Rusak Ringan'),
              const SizedBox(width: 8),
              _buildKondisiChip('RUSAK_BERAT', 'Rusak Berat'),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Catatan Hasil Pemeriksaan:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _catatanController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Kelengkapan, kebersihan, atau keluhan fisik...',
            ),
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: 'Konfirmasi Pengembalian Selesai',
            isLoading: _isSubmitting,
            icon: const Icon(LucideIcons.checkCheck, size: 18, color: Colors.white),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
