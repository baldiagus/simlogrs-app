import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_confirm_dialog.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../approval/presentation/providers/approval_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../gudang/data/models/po_inbound_model.dart';
import '../../../gudang/presentation/providers/inbound_provider.dart';
import '../../../gudang/presentation/screens/form_penerimaan_po_screen.dart';
import '../../data/models/po_model.dart';
import '../../data/models/pr_model.dart';
import '../providers/pengadaan_provider.dart';

/// Aksi dialog & navigasi pada Hub Pengadaan. Dipanggil dengan `context` dan
/// `ref` milik layar hub agar tetap valid meskipun tab berpindah.
class PengadaanHubActions {
  final WidgetRef ref;

  const PengadaanHubActions(this.ref);

  Future<void> setujuiPr(BuildContext context, PrHeaderModel pr) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Konfirmasi Persetujuan PR',
      message:
          'Setujui permohonan pengadaan ${pr.kode} dari ${pr.unit}?\n\nDokumen akan berstatus DISETUJUI dan siap diteruskan ke Bagian Pengadaan.',
      confirmLabel: 'Ya, Setujui PR',
      confirmColor: AppColors.success,
      icon: LucideIcons.checkCheck,
    );
    if (!confirmed || !context.mounted) return;

    final ok = await ref.read(approvalActionProvider.notifier).approvePr(
          id: pr.id,
          aksi: 'setujui',
        );
    if (!context.mounted) return;
    final state = ref.read(approvalActionProvider);
    if (ok) {
      AppToast.success(
          context, state.successMessage ?? 'PR berhasil disetujui.');
      ref.invalidate(daftarPrProvider);
      ref.invalidate(approvalPendingProvider);
      ref.invalidate(dashboardSummaryProvider);
    } else {
      AppToast.error(context, state.errorMessage ?? 'Gagal menyetujui PR.');
    }
  }

  Future<void> teruskanPr(BuildContext context, PrHeaderModel pr) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Teruskan PR ke Pengadaan',
      message:
          'Teruskan PR ${pr.kode} ke Bagian Pengadaan untuk proses penerbitan PO?',
      confirmLabel: 'Ya, Teruskan',
      confirmColor: AppColors.primaryPurple,
      icon: LucideIcons.send,
    );
    if (!confirmed || !context.mounted) return;

    final ok = await ref.read(approvalActionProvider.notifier).approvePr(
          id: pr.id,
          aksi: 'teruskan',
        );
    if (!context.mounted) return;
    final state = ref.read(approvalActionProvider);
    if (ok) {
      AppToast.success(context,
          state.successMessage ?? 'PR diteruskan ke Bagian Pengadaan.');
      ref.invalidate(daftarPrProvider);
      ref.invalidate(approvalPendingProvider);
      ref.invalidate(dashboardSummaryProvider);
    } else {
      AppToast.error(context, state.errorMessage ?? 'Gagal meneruskan PR.');
    }
  }

  void tolakPr(BuildContext context, PrHeaderModel pr,
      {bool isPengadaan = false}) {
    final catatanCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
            isPengadaan ? 'Tolak oleh Tim Pengadaan' : 'Tolak Permohonan PR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPengadaan
                  ? 'Masukkan alasan penolakan belanja untuk PR ${pr.kode}:'
                  : 'Masukkan catatan penolakan untuk PR ${pr.kode}:',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: catatanCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText:
                    'Misal: Melebihi plafon pagu atau barang tidak tersedia...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final catatan = catatanCtrl.text.trim();
              if (catatan.isEmpty) {
                AppToast.error(context, 'Alasan penolakan wajib dicantumkan.');
                return;
              }
              Navigator.pop(ctx);
              final ok =
                  await ref.read(approvalActionProvider.notifier).approvePr(
                        id: pr.id,
                        aksi: 'tolak',
                        catatan: catatan,
                      );
              if (!context.mounted) return;
              final state = ref.read(approvalActionProvider);
              if (ok) {
                AppToast.success(
                    context, state.successMessage ?? 'PR telah ditolak.');
                ref.invalidate(daftarPrProvider);
                ref.invalidate(approvalPendingProvider);
                ref.invalidate(dashboardSummaryProvider);
              } else {
                AppToast.error(
                    context, state.errorMessage ?? 'Gagal menolak PR.');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Ya, Tolak PR',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> confirmUpdateKirimPo(
      BuildContext context, PesananPembelianModel po) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Konfirmasi Pengiriman Vendor',
      message:
          'Ubah status pesanan ${po.kode} (Vendor: ${po.namaPemasok}) menjadi DIKIRIM_VENDOR? Menandakan barang pesanan sedang dalam perjalanan ekspedisi ke gudang.',
      confirmLabel: 'Ya, Tandai Dikirim',
      confirmColor: AppColors.tintBlue,
      icon: LucideIcons.truck,
    );
    if (!confirmed || !context.mounted) return;

    final notifier = ref.read(poActionProvider.notifier);
    final ok = await notifier.updateStatusKirim(po.id);
    if (!context.mounted) return;

    final state = ref.read(poActionProvider);
    if (ok) {
      AppToast.success(
          context,
          state.successMessage ??
              'Status pesanan berhasil ditandai dikirim vendor.');
      ref.invalidate(poListProvider);
      ref.invalidate(daftarPoInboundProvider);
      ref.invalidate(dashboardSummaryProvider);
    } else {
      AppToast.error(context,
          state.errorMessage ?? 'Gagal memperbarui status pengiriman PO.');
    }
  }

  Future<void> terimaInbound(
      BuildContext context, PoInboundHeaderModel item) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormPenerimaanPoScreen(po: item),
      ),
    );
    if (ok == true && context.mounted) {
      ref.invalidate(daftarPoInboundProvider);
      ref.invalidate(dashboardSummaryProvider);
    }
  }
}
