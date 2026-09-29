import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/app_formatters.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../distribusi/data/models/amprah_model.dart';
import '../../../distribusi/presentation/screens/form_pengajuan_amprah_screen.dart';
import '../../../pengadaan/data/models/master_barang_model.dart';
import '../../../pengadaan/presentation/screens/form_pengajuan_pr_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/detail_barang_sections.dart';
import '../providers/master_barang_provider.dart';

class DetailBarangScreen extends ConsumerWidget {
  final int barangId;
  final String? initialNama;

  const DetailBarangScreen({
    super.key,
    required this.barangId,
    this.initialNama,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(detailBarangProvider(barangId));


    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(initialNama ?? 'Profil Komoditas'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.refresh(detailBarangProvider(barangId)),
          ),
        ],
      ),
      body: detailAsync.when(
        loading: () => const AppLoadingView(),
        error: (err, _) => AppErrorView(
          error: err,
          onRetry: () => ref.refresh(detailBarangProvider(barangId)),
        ),
        data: (detail) {
          final b = detail.master;
          final isAset = b.tipe == 'ASET';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero Card Komoditas
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryHeroGradient,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                b.kode,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                b.tipeLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          b.nama,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${b.kategori} • Satuan: ${b.satuan} (${b.simbolSatuan})',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          b.hargaEstimasi > 0
                              ? 'Estimasi: ${AppFormatters.rupiah(b.hargaEstimasi)} / ${b.simbolSatuan}'
                              : (b.hargaBeliTerakhir > 0
                                  ? 'Beli Terakhir: ${AppFormatters.rupiah(b.hargaBeliTerakhir)} / ${b.simbolSatuan}'
                                  : 'Estimasi: Rp 0 / ${b.simbolSatuan}'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Parameter Logistik & Pengadaan
                  DetailBarangParamCard(b: b),
                  const SizedBox(height: 16),
                  // Tombol Aksi Tambah Permintaan PR & Permintaan Distribusi (Hanya untuk Pemohon / Non-Teknisi)
                  () {
                    final user = ref.watch(authStateProvider).user;
                    if (user?.isTeknisi == true) return const SizedBox.shrink();
                    final isPengadaan = user?.isPengadaan ?? false;

                    final amprahWidget = InkWell(
                      onTap: () {
                        final amprahBarang = BarangAmprahKatalogModel(
                          id: b.id,
                          kode: b.kode,
                          nama: b.nama,
                          spesifikasi: b.spesifikasi,
                          tipe: b.tipe,
                          tipeLabel: b.tipeLabel,
                          kategori: b.kategori,
                          satuan: b.satuan,
                          merek: b.merek,
                          stokTersedia: b.stokGudang,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FormPengajuanAmprahScreen(initialBarang: amprahBarang),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: isPengadaan ? AppColors.tintBlueBg : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.tintBlue, width: 1.5),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.truck, size: 16, color: AppColors.tintBlue),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Minta Amprah',
                                style: TextStyle(
                                  color: AppColors.tintBlue,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    final prWidget = InkWell(
                      onTap: () {
                        final prBarang = MasterBarangModel(
                          id: b.id,
                          kode: b.kode,
                          nama: b.nama,
                          spesifikasi: b.spesifikasi,
                          tipe: b.tipe,
                          tipeLabel: b.tipeLabel,
                          kategori: b.kategori,
                          satuan: b.satuan,
                          merek: b.merek,
                          hargaEstimasi: b.hargaEstimasi,
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FormPengajuanPrScreen(initialBarang: prBarang),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(91, 80, 230, 0.25),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.shoppingCart, size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Tambah PR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    return Column(
                      children: [
                        if (isPengadaan)
                          SizedBox(width: double.infinity, child: amprahWidget)
                        else
                          Row(
                            children: [
                              Expanded(child: prWidget),
                              const SizedBox(width: 12),
                              Expanded(child: amprahWidget),
                            ],
                          ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }(),
                  if (isAset) ...[
                    DetailBarangAsetList(daftarAset: detail.daftarAset),
                    if (detail.daftarBatch.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      DetailBarangBatchList(
                        daftarBatch: detail.daftarBatch,
                        simbolSatuan: b.simbolSatuan,
                      ),
                    ],
                  ] else ...[
                    DetailBarangBatchList(
                      daftarBatch: detail.daftarBatch,
                      simbolSatuan: b.simbolSatuan,
                    ),
                    const SizedBox(height: 20),
                    DetailBarangRuanganList(
                      daftarRuangan: detail.daftarRuangan,
                      simbolSatuan: b.simbolSatuan,
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}
