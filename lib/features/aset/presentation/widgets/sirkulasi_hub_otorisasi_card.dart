import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/peminjaman_aset_model.dart';

/// Kartu permohonan peminjaman pada tab Otorisasi.
///
/// [onAksi] dipanggil dengan 'tolak', 'setujui', atau 'serah_terima'.
class SirkulasiHubOtorisasiCard extends StatelessWidget {
  const SirkulasiHubOtorisasiCard(
      {super.key, required this.item, required this.onAksi});

  final ApprovalPeminjamanModel item;
  final ValueChanged<String> onAksi;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.tintVioletBg,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(item.kode,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryPurple)),
              ),
              StatusBadge(status: item.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(item.namaAset,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(
              'Kode: ${item.kodeAset} • Pemohon: ${item.unitPeminjam} (${item.pengaju})',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
              'Jadwal: ${item.tanggalPinjam} s/d ${item.tanggalKembaliRencana}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (item.keperluan.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Keperluan: ${item.keperluan}',
                style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),

          // Action buttons
          if (item.isDiajukan)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onAksi('tolak'),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFCA5A5))),
                    child: const Text('Tolak',
                        style: TextStyle(color: AppColors.danger)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onAksi('setujui'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white),
                    child: const Text('Setujui Pinjam'),
                  ),
                ),
              ],
            )
          else if (item.isDisetujui)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onAksi('serah_terima'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white),
                icon: const Icon(LucideIcons.arrowRightLeft, size: 16),
                label: const Text('Serah Terima Fisik ke Peminjam'),
              ),
            ),
        ],
      ),
    );
  }
}
