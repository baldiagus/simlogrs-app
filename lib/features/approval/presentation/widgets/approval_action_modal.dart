import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../data/models/approval_item_model.dart';
import '../providers/approval_provider.dart';

class ApprovalActionModal extends ConsumerStatefulWidget {
  final ApprovalItemModel item;
  final String aksi; // 'setujui', 'tolak', 'serahkan'

  const ApprovalActionModal({
    super.key,
    required this.item,
    required this.aksi,
  });

  static Future<void> show(
    BuildContext context, {
    required ApprovalItemModel item,
    required String aksi,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApprovalActionModal(item: item, aksi: aksi),
    );
  }

  @override
  ConsumerState<ApprovalActionModal> createState() => _ApprovalActionModalState();
}

class _ApprovalActionModalState extends ConsumerState<ApprovalActionModal> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSetujui = widget.aksi == 'setujui';
    final isSerahkan = widget.aksi == 'serahkan';

    final Color themeColor = isSetujui
        ? AppColors.success
        : (isSerahkan ? AppColors.primaryPurple : AppColors.danger);
    final IconData icon = isSetujui
        ? LucideIcons.checkCheck
        : (isSerahkan ? LucideIcons.send : LucideIcons.alertTriangle);
    final String modalTitle = isSetujui
        ? 'Setujui Dokumen'
        : (isSerahkan ? 'Serahkan ke Bagian Pengadaan' : 'Tolak Dokumen');
    final String buttonLabel = isSetujui
        ? 'Ya, Setujui'
        : (isSerahkan ? 'Ya, Serahkan ke Pengadaan' : 'Ya, Tolak');

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
                      '${widget.item.kode} • ${widget.item.unit}',
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
                  : (isSerahkan
                      ? 'Catatan pelimpahan ke bagian pengadaan...'
                      : 'Alasan penolakan dokumen (wajib)...'),
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
            onPressed: () async {
              final catatan = _noteController.text.trim();
              if (!isSetujui && !isSerahkan && catatan.isEmpty) {
                AppToast.error(context, 'Alasan penolakan wajib diisi!');
                return;
              }
              final ok = await ref.read(approvalActionProvider.notifier).eksekusi(
                    id: widget.item.id,
                    tipe: widget.item.tipe,
                    aksi: widget.aksi,
                    catatan: catatan,
                  );
              if (!context.mounted) return;
              final state = ref.read(approvalActionProvider);
              if (ok) {
                AppToast.success(context, state.successMessage ?? 'Berhasil');
                Navigator.pop(context, true);
              } else {
                AppToast.error(context, state.errorMessage ?? 'Gagal');
              }
            },
          ),
        ],
      ),
    );
  }
}
