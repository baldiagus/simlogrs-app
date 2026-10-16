import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/models/peminjaman_aset_model.dart';

/// Kartu permohonan peminjaman pada tab Otorisasi.
///
/// [onAksi] dipanggil dengan 'tolak', 'setujui', atau 'serah_terima'.
class SirkulasiHubOtorisasiCard extends StatelessWidget {
  /// Membuat kartu otorisasi untuk [item] dengan callback aksi [onAksi].
  const SirkulasiHubOtorisasiCard(
      {super.key, required this.item, required this.onAksi});

  final ApprovalPeminjamanModel item;
  final ValueChanged<String> onAksi;

  /// Membangun kartu permohonan beserta tombol aksi yang memanggil [onAksi].
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
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
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
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 6),

          // 1. Asset Code Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
            decoration: BoxDecoration(
              color: AppColors.surfaceSecondary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item.kodeAset,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryPurple,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // 2. Pemohon Row (wrap alami)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(LucideIcons.user, size: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pemohon: ${item.unitPeminjam} (${item.pengaju})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 3. Rentang Tanggal Peminjaman (Terformat Standar RS)
          Row(
            children: [
              const Icon(LucideIcons.calendar, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Jadwal: ${AppFormatters.tanggalString(item.tanggalPinjam)} s/d ${AppFormatters.tanggalString(item.tanggalKembaliRencana)}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // 4. Catatan Keperluan Terpadu
          if (item.keperluan.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1.5),
                    child: Icon(LucideIcons.fileText, size: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Keperluan: ${item.keperluan}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
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
