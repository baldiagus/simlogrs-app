import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/aset_detail_model.dart';

class AsetInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? badge;

  const AsetInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryPurple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        if (badge != null) badge!,
      ],
    );
  }
}

class AsetDetailLokasiCard extends StatelessWidget {
  final AsetDetailModel aset;

  const AsetDetailLokasiCard({super.key, required this.aset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          AsetInfoRow(
            icon: LucideIcons.mapPin,
            label: 'Lokasi Tercatat Saat Ini',
            value: aset.lokasiTercatat,
          ),
          const Divider(color: AppColors.border, height: 20),
          AsetInfoRow(
            icon: LucideIcons.userCheck,
            label: 'Penanggung Jawab / Peminjam',
            value: aset.penanggungJawab,
          ),
          const Divider(color: AppColors.border, height: 20),
          AsetInfoRow(
            icon: LucideIcons.activity,
            label: 'Kondisi Fisik',
            value: aset.kondisi.replaceAll('_', ' '),
            badge: StatusBadge(status: aset.kondisi),
          ),
        ],
      ),
    );
  }
}

class AsetDetailSpesifikasiCard extends StatelessWidget {
  final AsetDetailModel aset;

  const AsetDetailSpesifikasiCard({super.key, required this.aset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.fileSpreadsheet, size: 16, color: AppColors.primaryPurple),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Spesifikasi & Nilai Perolehan',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AsetInfoRow(
            icon: LucideIcons.tag,
            label: 'Merek Pabrikan',
            value: aset.merek,
          ),
          const Divider(color: AppColors.border, height: 16),
          AsetInfoRow(
            icon: LucideIcons.banknote,
            label: 'Nilai Perolehan Awal',
            value: aset.nilaiPerolehan > 0 ? AppFormatters.rupiah(aset.nilaiPerolehan) : '-',
          ),
          const Divider(color: AppColors.border, height: 16),
          AsetInfoRow(
            icon: LucideIcons.calendarCheck2,
            label: 'Tanggal Perolehan RS',
            value: aset.tanggalPerolehan,
          ),
          if (aset.spesifikasi != '-') ...[
            const Divider(color: AppColors.border, height: 16),
            AsetInfoRow(
              icon: LucideIcons.cpu,
              label: 'Spesifikasi / Kapasitas',
              value: aset.spesifikasi,
            ),
          ],
        ],
      ),
    );
  }
}

class AsetDetailIpsrsCard extends StatelessWidget {
  final AsetDetailModel aset;
  final VoidCallback onTap;

  const AsetDetailIpsrsCard({super.key, required this.aset, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Icon(LucideIcons.wrench, size: 16, color: AppColors.primaryPurple),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Histori Pemeliharaan (IPSRS)',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: aset.totalRiwayatServis > 0
                            ? AppColors.tintOrangeBg
                            : AppColors.surfaceSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${aset.totalRiwayatServis}x Servis',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: aset.totalRiwayatServis > 0
                              ? AppColors.tintOrange
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.primaryPurple),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (aset.servisTerakhir != null) ...[
              Container(
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            aset.servisTerakhir!.kode,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                              color: AppColors.primaryPurple,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: aset.servisTerakhir!.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      aset.servisTerakhir!.deskripsi,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tgl: ${aset.servisTerakhir!.tanggalPengajuan}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Buka Rekam Medis & Preventif',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primaryPurple),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(LucideIcons.arrowRight, size: 12, color: AppColors.primaryPurple),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.checkCircle2, size: 16, color: AppColors.success),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Belum ada catatan servis kerusakan. Buka rekam medis alat...',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(LucideIcons.arrowRight, size: 14, color: AppColors.primaryPurple),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AsetDetailActiveLoanCard extends StatelessWidget {
  final PeminjamanAktifInfo loan;

  const AsetDetailActiveLoanCard({super.key, required this.loan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(LucideIcons.repeat, size: 16, color: AppColors.primaryPurple),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Transaksi Peminjaman Aktif',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AsetInfoRow(
            icon: LucideIcons.fileText,
            label: 'Kode Peminjaman',
            value: loan.kodePinjam,
          ),
          const Divider(color: AppColors.border, height: 16),
          AsetInfoRow(
            icon: LucideIcons.building,
            label: 'Unit Peminjam',
            value: loan.unitPeminjam,
          ),
          const Divider(color: AppColors.border, height: 16),
          AsetInfoRow(
            icon: LucideIcons.calendar,
            label: 'Batas Rencana Kembali',
            value: loan.tanggalKembaliRencana ?? '-',
          ),
        ],
      ),
    );
  }
}
