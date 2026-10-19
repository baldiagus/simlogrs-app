import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../maintenance/presentation/screens/lapor_cepat_screen.dart';
import '../../data/models/aset_detail_model.dart';
import '../../data/models/aset_tersedia_model.dart';
import '../screens/form_peminjaman_aset_screen.dart';
import 'aset_detail_loan_actions.dart';
import 'modal_pengalihan_aset_sheet.dart';

/// Kumpulan tombol aksi di bagian bawah profil aset (peminjaman,
/// pengembalian, pengalihan, dan lapor kerusakan).
class AsetDetailActionSection extends StatelessWidget {
  final AsetDetailModel aset;
  final bool isOwnedByCurrentUserLocation;
  final bool isGlobalAdmin;
  final bool isProviderOwner;
  final bool canPinjam;
  final bool canLaporRusak;
  final bool canPerpanjang;
  final bool canPengalihan;
  final bool isActionLoading;
  final VoidCallback onPerpanjang;
  final VoidCallback onPengembalian;

  /// Membuat section aksi dengan data aset, hak akses, dan callback aksi.
  const AsetDetailActionSection({
    super.key,
    required this.aset,
    required this.isOwnedByCurrentUserLocation,
    required this.isGlobalAdmin,
    required this.isProviderOwner,
    required this.canPinjam,
    required this.canLaporRusak,
    this.canPerpanjang = false,
    this.canPengalihan = false,
    required this.isActionLoading,
    required this.onPerpanjang,
    required this.onPengembalian,
  });

  /// Membuka form peminjaman dengan aset ini sudah terisi, supaya
  /// pengguna tidak perlu mencari aset lagi di katalog.
  void _ajukanPeminjaman(BuildContext context) {
    // Buat AsetTersediaModel dari aset untuk prefill form peminjaman
    final asetTersedia = AsetTersediaModel(
      id: aset.id,
      kodeAset: aset.kodeAset,
      nomorSeri: aset.nomorSeri,
      namaKomoditas: aset.namaKomoditas,
      spesifikasi: aset.spesifikasi,
      kategori: aset.kategori,
      satuan: 'Unit',
      merek: aset.merek,
      kondisi: aset.kondisi,
      tipePenyedia: aset.tipePenyedia ??
          (aset.gudangId != null
              ? 'GUDANG'
              : (aset.lokasiTercatat.contains('Rak:') ? 'GUDANG' : 'RUANGAN')),
      penyediaId: aset.penyediaId ?? (aset.gudangId ?? aset.unitId),
      namaPenyedia: aset.namaPenyedia ?? aset.penanggungJawab,
      lokasiLengkap: aset.lokasiTercatat,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FormPeminjamanAsetScreen(preselectedAset: asetTersedia),
      ),
    );
  }

  /// Membuka modal pengalihan/mutasi aset dengan data aset ini sebagai
  /// aset terpilih, agar unit pemohon tidak perlu memilih ulang.
  void _ajukanPengalihan(BuildContext context) {
    final asetTersedia = AsetTersediaModel(
      id: aset.id,
      kodeAset: aset.kodeAset,
      nomorSeri: aset.nomorSeri,
      namaKomoditas: aset.namaKomoditas,
      spesifikasi: aset.spesifikasi,
      kategori: aset.kategori,
      satuan: 'Unit',
      merek: aset.merek,
      kondisi: aset.kondisi,
      tipePenyedia:
          aset.tipePenyedia ?? (aset.gudangId != null ? 'GUDANG' : 'RUANGAN'),
      penyediaId: aset.penyediaId ?? (aset.gudangId ?? aset.unitId ?? 0),
      namaPenyedia: aset.namaPenyedia ?? aset.penanggungJawab,
      lokasiLengkap: aset.lokasiTercatat,
    );
    ModalPengalihanAsetSheet.show(context, aset: asetTersedia);
  }

  /// Menyusun tombol aksi sesuai status aset: pinjam, perpanjang/kembali,
  /// pengalihan, dan lapor kerusakan berdasarkan hak akses pengguna.
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (aset.isDipinjam && aset.peminjamanAktif != null) ...[
          AsetDetailLoanActions(
            aset: aset,
            isProviderOwner: isProviderOwner,
            isActionLoading: isActionLoading,
            canPerpanjang: canPerpanjang,
            onPerpanjang: onPerpanjang,
            onPengembalian: onPengembalian,
          ),
          const SizedBox(height: 10),
        ] else if (canPinjam) ...[
          CustomButton(
            text: 'Ajukan Peminjaman Aset',
            icon: const Icon(LucideIcons.repeat, size: 18, color: Colors.white),
            onPressed: () => _ajukanPeminjaman(context),
          ),
          const SizedBox(height: 10),
        ] else if (!isOwnedByCurrentUserLocation &&
            aset.isSedangDalamProsesPinjam &&
            !aset.isDipinjam) ...[
          AsetDetailProsesPinjamNotice(aset: aset),
        ],

        // Tombol Lapor Kerusakan ke IPSRS (Hanya untuk non-teknisi / pemohon ruangan)
        // Tombol Pengalihan / Mutasi Aset (Meminta aset dari fasilitas lain masuk ke unit kerja Anda)
        if (canPengalihan) ...[
          OutlinedButton.icon(
            onPressed: () => _ajukanPengalihan(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.primaryPurple),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(LucideIcons.arrowRightLeft,
                size: 18, color: AppColors.primaryPurple),
            label: const Text(
              'Pengalihan / Mutasi Aset',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryPurple),
            ),
          ),
          const SizedBox(height: 10),
        ],

        if (canLaporRusak) ...[
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      LaporCepatScreen(initialKodeAset: aset.kodeAset),
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.danger),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(LucideIcons.wrench,
                size: 18, color: AppColors.danger),
            label: const Text(
              'Lapor Kerusakan Alat (IPSRS)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.danger),
            ),
          ),
          const SizedBox(height: 30),
        ] else
          const SizedBox(height: 20),
      ],
    );
  }
}
