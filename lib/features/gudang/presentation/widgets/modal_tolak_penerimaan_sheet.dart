import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_sheet_wrapper.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../data/models/po_inbound_model.dart';
import '../providers/inbound_provider.dart';

/// Bottom sheet untuk menolak kiriman fisik PO: isi nomor surat jalan dan alasan penolakan.
class ModalTolakPenerimaanSheet extends ConsumerStatefulWidget {
  final PoInboundHeaderModel po;
  final String nomorSuratJalanAwal;

  const ModalTolakPenerimaanSheet({
    super.key,
    required this.po,
    required this.nomorSuratJalanAwal,
  });

  /// Menampilkan modal penolakan; hasil `true` bila penolakan berhasil.
  static Future<bool?> show(
    BuildContext context, {
    required PoInboundHeaderModel po,
    required String nomorSuratJalanAwal,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ModalTolakPenerimaanSheet(
        po: po,
        nomorSuratJalanAwal: nomorSuratJalanAwal,
      ),
    );
  }

  /// Membuat state form penolakan penerimaan.
  @override
  ConsumerState<ModalTolakPenerimaanSheet> createState() => _ModalTolakPenerimaanSheetState();
}

/// State form penolakan; mengelola form key serta controller surat jalan dan alasan.
class _ModalTolakPenerimaanSheetState extends ConsumerState<ModalTolakPenerimaanSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _suratJalanController;
  final _alasanController = TextEditingController();

  /// Mengisi controller surat jalan dengan nilai awal dari PO.
  @override
  void initState() {
    super.initState();
    _suratJalanController = TextEditingController(text: widget.nomorSuratJalanAwal);
  }

  /// Membersihkan controller surat jalan dan alasan.
  @override
  void dispose() {
    _suratJalanController.dispose();
    _alasanController.dispose();
    super.dispose();
  }

  /// Validasi form lalu kirim penolakan seluruh sisa item PO ke API; tampilkan toast dan tutup sheet bila sukses.
  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(inboundActionProvider.notifier);
    final itemsPayload = widget.po.items.map((i) {
      return {
        'barang_id': i.barangId,
        'jumlah_rusak': i.sisaKebutuhan,
        'harga_satuan': i.hargaSatuan,
      };
    }).toList();

    final ok = await notifier.tolakPenerimaan(
      poId: widget.po.id,
      nomorSuratJalan: _suratJalanController.text.trim(),
      alasanPenolakan: _alasanController.text.trim(),
      items: itemsPayload,
    );

    if (!mounted) return;
    final state = ref.read(inboundActionProvider);

    if (ok) {
      AppToast.success(context, state.successMessage ?? 'Kiriman fisik berhasil ditolak.');
      Navigator.pop(context, true);
    } else {
      AppToast.error(context, state.errorMessage ?? 'Gagal menolak kiriman.');
    }
  }

  /// Membangun form penolakan dengan field surat jalan, alasan, dan tombol kirim.
  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(inboundActionProvider);

    return AppBottomSheetWrapper(
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.ban, color: AppColors.danger, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tolak Pengiriman Fisik',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.po.kodePo} • ${widget.po.pemasok}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.2)),
              ),
              child: const Text(
                'Penolakan ini menerbitkan Surat Penolakan Barang (Berita Acara) dengan dampak stok 0. Vendor berkewajiban mengirimkan barang pengganti.',
                style: TextStyle(fontSize: 11, color: AppColors.danger, height: 1.3),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _suratJalanController,
              decoration: const InputDecoration(
                labelText: 'Nomor Surat Jalan Fisik (Wajib)',
                prefixIcon: Icon(LucideIcons.fileText, size: 18),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Nomor surat jalan wajib diisi' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('field_alasan_penolakan'),
              controller: _alasanController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alasan Penolakan Fisik (Wajib)',
                hintText: 'Misal: Barang basah / kedaluwarsa / kemasan pecah...',
                prefixIcon: Icon(LucideIcons.messageSquareWarning, size: 18),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Alasan penolakan wajib diisi' : null,
            ),
            const SizedBox(height: 22),
            CustomButton(
              text: 'Terbitkan Surat Penolakan',
              backgroundColor: AppColors.danger,
              textColor: Colors.white,
              isLoading: actionState.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
