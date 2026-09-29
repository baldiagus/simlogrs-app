import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simlog_mobile/core/theme/app_colors.dart';
import 'package:simlog_mobile/features/aset/data/models/peminjaman_aset_model.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/peminjaman_provider.dart';
import 'package:simlog_mobile/shared/widgets/app_bottom_sheet_wrapper.dart';

class ModalOtorisasiPeminjamanSheet extends ConsumerStatefulWidget {
  final ApprovalPeminjamanModel item;
  final String aksi;
  final VoidCallback? onSuccess;

  const ModalOtorisasiPeminjamanSheet({
    super.key,
    required this.item,
    required this.aksi,
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required ApprovalPeminjamanModel item,
    required String aksi,
    VoidCallback? onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalOtorisasiPeminjamanSheet(
        item: item,
        aksi: aksi,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<ModalOtorisasiPeminjamanSheet> createState() =>
      _ModalOtorisasiPeminjamanSheetState();
}

class _ModalOtorisasiPeminjamanSheetState
    extends ConsumerState<ModalOtorisasiPeminjamanSheet> {
  final TextEditingController _catatanController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _submit(Color color, String buttonText) async {
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final notifier = ref.read(peminjamanActionProvider.notifier);
    final ok = await notifier.otorisasi(
      id: widget.item.id,
      aksi: widget.aksi,
      catatan: _catatanController.text.trim(),
    );

    navigator.pop();
    final state = ref.read(peminjamanActionProvider);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok
            ? (state.successMessage ?? 'Operasi berhasil.')
            : (state.errorMessage ?? 'Gagal memproses.')),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ),
    );

    if (ok) {
      widget.onSuccess?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSetujui = widget.aksi == 'setujui';
    final isSerahTerima = widget.aksi == 'serah_terima';
    final Color color = isSetujui
        ? AppColors.success
        : (isSerahTerima ? AppColors.primaryPurple : AppColors.danger);
    final String title = isSetujui
        ? 'Setujui Permohonan Pinjam'
        : (isSerahTerima ? 'Konfirmasi Serah Terima Fisik' : 'Tolak Permohonan Pinjam');
    final String buttonText = isSetujui
        ? 'Ya, Setujui'
        : (isSerahTerima ? 'Ya, Serahkan Fisik Aset' : 'Ya, Tolak Permohonan');

    return AppBottomSheetWrapper(
      title: title,
      subtitle:
          'Dokumen: ${widget.item.kode} • Aset: ${widget.item.namaAset} (${widget.item.kodeAset})',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Catatan Tambahan (Opsional):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _catatanController,
            maxLines: 2,
            decoration: const InputDecoration(hintText: 'Tambahkan keterangan otorisasi...'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : () => _submit(color, buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(buttonText),
          ),
        ],
      ),
    );
  }
}
