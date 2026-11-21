import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';

/// Konten tab Pengalihan saat daftar kosong: banner otorisasi tertunda
/// (khusus tab Aktif) dan empty state dengan tombol ajukan opsional.
class PengalihanEmptyTab extends StatelessWidget {
  final String tab;
  final int countOtorisasi;
  final bool isAset;
  final bool canCreate;
  final Future<void> Function() onRefresh;
  final VoidCallback onBukaOtorisasi;
  final VoidCallback onCreate;

  /// Membuat tab kosong pengalihan dengan callback refresh, buka otorisasi, dan ajukan.
  const PengalihanEmptyTab({
    super.key,
    required this.tab,
    required this.countOtorisasi,
    required this.isAset,
    required this.canCreate,
    required this.onRefresh,
    required this.onBukaOtorisasi,
    required this.onCreate,
  });

  /// Label jenis objek pengalihan (aset atau barang persediaan) untuk teks UI.
  String get _tipeLabel => isAset ? 'aset' : 'barang persediaan';

  /// Membangun tampilan kosong yang tetap bisa di-refresh.
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        child: Column(
          children: [
            if (tab == 'aktif' && countOtorisasi > 0) _buildOtorisasiBanner(context),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.55,
              child: EmptyStateView(
                icon: LucideIcons.arrowRightLeft,
                title: 'Belum Ada Pengalihan',
                message: tab == 'aktif'
                    ? (countOtorisasi > 0
                        ? 'Tidak ada permohonan aktif keluar/masuk. Periksa tab Otorisasi untuk permohonan dari fasilitas lain.'
                        : 'Tidak ada pengalihan $_tipeLabel yang sedang berjalan.')
                    : (tab == 'otorisasi'
                        ? 'Tidak ada dokumen pengalihan yang menunggu otorisasi Anda.'
                        : 'Belum ada riwayat mutasi yang diselesaikan.'),
                action: (tab != 'aktif' || !canCreate)
                    ? null
                    : _buildCreateButton(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun banner peringatan jumlah otorisasi pengalihan yang tertunda.
  Widget _buildOtorisasiBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.alertCircle,
                color: AppColors.warning, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Terdapat $countOtorisasi permohonan pengalihan $_tipeLabel menunggu persetujuan Anda di tab Otorisasi.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onBukaOtorisasi,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryPurple,
                visualDensity: VisualDensity.compact,
              ),
              child: Text('Buka',
                  style: Theme.of(context).textTheme.labelMedium),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun tombol ajukan pengalihan pada empty state.
  Widget _buildCreateButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onCreate,
      style: ElevatedButton.styleFrom(
        backgroundColor: isAset ? AppColors.primaryPurple : AppColors.tintBlue,
        foregroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(LucideIcons.plus, size: 16),
      label:
          Text(isAset ? 'Ajukan Pengalihan Aset' : 'Ajukan Pengalihan Barang'),
    );
  }
}
