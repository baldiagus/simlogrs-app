import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
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
  static Future<void> show(
    BuildContext context, {
    required AmprahHeaderModel amprah,
    required bool isSetujui,
  }) {
    return showModalBottomSheet(
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

  /// Membersihkan controller catatan agar tidak bocor memori.
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// Memvalidasi alasan tolak (wajib), lalu mengirim keputusan dan menutup modal bila berhasil.
  Future<void> _kirim(BuildContext context) async {
    final catatan = _noteController.text.trim();
    if (!widget.isSetujui && catatan.isEmpty) {
      AppToast.error(context, 'Alasan penolakan wajib diisi!');
      return;
    }
    final ok = await ref.read(amprahActionProvider.notifier).approveAmprah(
          id: widget.amprah.id,
          isSetujui: widget.isSetujui,
          catatan: catatan,
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
          const SizedBox(height: 20),
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
