import 'package:flutter/material.dart';
import '../../data/models/aset_detail_model.dart';
import '../screens/histori_pengalihan_aset_screen.dart';
import '../screens/histori_sirkulasi_aset_screen.dart';
import 'aset_histori_pengalihan_card.dart';
import 'aset_riwayat_peminjaman_card.dart';

/// Riwayat sirkulasi peminjaman dan pengalihan/mutasi fisik aset.
class AsetDetailRiwayatSection extends StatelessWidget {
  final AsetDetailModel aset;

  const AsetDetailRiwayatSection({super.key, required this.aset});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 7. Riwayat Sirkulasi Peminjaman Unit
        AsetRiwayatPeminjamanCard(
          riwayat: aset.riwayatPeminjaman,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoriSirkulasiAsetScreen(
                  asetId: aset.id,
                  kodeAset: aset.kodeAset,
                  namaKomoditas: aset.namaKomoditas,
                  nomorSeri: aset.nomorSeri,
                  initialRiwayat: aset.riwayatPeminjaman,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // 8. Riwayat Pengalihan & Mutasi Fisik
        AsetHistoriPengalihanCard(
          riwayat: aset.riwayatPengalihan,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HistoriPengalihanAsetScreen(
                  asetId: aset.id,
                  kodeAset: aset.kodeAset,
                  namaKomoditas: aset.namaKomoditas,
                  nomorSeri: aset.nomorSeri,
                  initialRiwayat: aset.riwayatPengalihan,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
