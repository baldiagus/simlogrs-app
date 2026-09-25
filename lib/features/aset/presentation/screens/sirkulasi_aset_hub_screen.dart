import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/peminjaman_aset_model.dart';
import '../providers/aset_provider.dart';
import '../providers/peminjaman_provider.dart';
import '../widgets/peminjaman_card_item.dart';
import 'form_peminjaman_aset_screen.dart';
import 'qr_scanner_screen.dart';

class SirkulasiAsetHubScreen extends ConsumerStatefulWidget {
  const SirkulasiAsetHubScreen({super.key});

  @override
  ConsumerState<SirkulasiAsetHubScreen> createState() => _SirkulasiAsetHubScreenState();
}

class _SirkulasiAsetHubScreenState extends ConsumerState<SirkulasiAsetHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _canApprove = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;
    _canApprove = (user?.can('layanan_unit::approval::peminjaman') ?? false) ||
        (user?.can('view_any_layanan_unit::approval::karu') ?? false) ||
        (user?.hasRole('kepala_unit') ?? false) ||
        (user?.hasRole('kepala_gudang') ?? false) ||
        (user?.hasRole('admin_logistik') ?? false) ||
        (user?.hasRole('super_admin') ?? false);

    _tabController = TabController(length: _canApprove ? 3 : 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showReturnModal(BuildContext context, PeminjamanAsetModel item) {
    final firstItem = item.items.isNotEmpty ? item.items.first : null;
    if (firstItem == null) return;

    String kondisi = 'BAIK';
    final catatanController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.tintOrangeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.packageCheck, size: 22, color: AppColors.tintOrange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inspeksi Pengembalian Fisik',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${item.kode} • ${firstItem.namaKomoditas}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              const Text(
                'Kondisi Fisik Saat Kembali:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildKondisiChip('BAIK', 'Baik', kondisi, (v) => setModalState(() => kondisi = v)),
                  const SizedBox(width: 8),
                  _buildKondisiChip('RUSAK_RINGAN', 'Rusak Ringan', kondisi, (v) => setModalState(() => kondisi = v)),
                  const SizedBox(width: 8),
                  _buildKondisiChip('RUSAK_BERAT', 'Rusak Berat', kondisi, (v) => setModalState(() => kondisi = v)),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Catatan Hasil Pemeriksaan:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: catatanController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Kelengkapan, kebersihan, atau keluhan fisik...',
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  final notifier = ref.read(asetActionProvider.notifier);
                  final ok = await notifier.konfirmasiPengembalian(
                    peminjamanId: item.id,
                    inspeksi: [
                      {
                        'permintaan_peminjaman_detail_id': firstItem.id,
                        'aset_id': firstItem.asetId,
                        'kondisi_saat_kembali': kondisi,
                        'catatan': catatanController.text.trim(),
                      }
                    ],
                    catatan: catatanController.text.trim(),
                  );

                  if (!mounted) return;
                  final state = ref.read(asetActionProvider);
                  ref.invalidate(daftarPeminjamanSayaProvider);
                  ref.invalidate(daftarPeminjamanAktifDipinjamProvider);

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(ok ? (state.successMessage ?? 'Pengembalian berhasil diproses.') : (state.errorMessage ?? 'Gagal memproses pengembalian.')),
                      backgroundColor: ok ? AppColors.success : AppColors.danger,
                    ),
                  );
                },
                icon: const Icon(LucideIcons.checkCheck, size: 18),
                label: const Text('Terima Pengembalian Fisik'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKondisiChip(String val, String label, String currentVal, ValueChanged<String> onSelect) {
    final isSelected = currentVal == val;
    Color color = AppColors.success;
    if (val == 'RUSAK_RINGAN') color = AppColors.warning;
    if (val == 'RUSAK_BERAT') color = AppColors.danger;

    return Expanded(
      child: InkWell(
        onTap: () => onSelect(val),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSelected ? color : AppColors.border, width: isSelected ? 1.5 : 1.0),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? color : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _showOtorisasiModal(BuildContext context, ApprovalPeminjamanModel item, String aksi) {
    final isSetujui = aksi == 'setujui';
    final isSerahTerima = aksi == 'serah_terima';
    final Color color = isSetujui
        ? AppColors.success
        : (isSerahTerima ? AppColors.primaryPurple : AppColors.danger);
    final String title = isSetujui
        ? 'Setujui Permohonan Pinjam'
        : (isSerahTerima ? 'Konfirmasi Serah Terima Fisik' : 'Tolak Permohonan Pinjam');
    final String buttonText = isSetujui
        ? 'Ya, Setujui'
        : (isSerahTerima ? 'Ya, Serahkan Fisik Aset' : 'Ya, Tolak Permohonan');

    final catatanController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('Dokumen: ${item.kode} • Aset: ${item.namaAset} (${item.kodeAset})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            const Text('Catatan Tambahan (Opsional):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: catatanController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Tambahkan keterangan otorisasi...'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(ctx);
                final notifier = ref.read(peminjamanActionProvider.notifier);
                final ok = await notifier.otorisasi(
                  id: item.id,
                  aksi: aksi,
                  catatan: catatanController.text.trim(),
                );

                if (!mounted) return;
                final state = ref.read(peminjamanActionProvider);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(ok ? (state.successMessage ?? 'Operasi berhasil.') : (state.errorMessage ?? 'Gagal memproses.')),
                    backgroundColor: ok ? AppColors.success : AppColors.danger,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final peminjamanSayaAsync = ref.watch(daftarPeminjamanSayaProvider);
    final approvalPeminjamanAsync = ref.watch(daftarApprovalPeminjamanProvider);
    final peminjamanAktifAsync = ref.watch(daftarPeminjamanAktifDipinjamProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Sirkulasi Aset RS'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.qrCode, size: 20),
            tooltip: 'Buka Kamera Scanner',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Segarkan Data',
            onPressed: () {
              ref.invalidate(daftarPeminjamanSayaProvider);
              ref.invalidate(daftarApprovalPeminjamanProvider);
              ref.invalidate(daftarPeminjamanAktifDipinjamProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          tabs: [
            const Tab(
              child: Text(
                'Pinjaman Saya',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_canApprove)
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Flexible(
                      child: Text(
                        'Otorisasi',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _buildBadge(approvalPeminjamanAsync.valueOrNull?.length ?? 0),
                  ],
                ),
              ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Text(
                      'Siap Kembali',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildBadge(peminjamanAktifAsync.valueOrNull?.length ?? 0),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: (ref.watch(authStateProvider).user?.unit != null)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FormPeminjamanAsetScreen()));
              },
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: const Text('Pinjam Aset Baru', style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Peminjaman Saya
          peminjamanSayaAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(daftarPeminjamanSayaProvider),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: EmptyStateView(
                        icon: LucideIcons.armchair,
                        title: 'Belum Ada Peminjaman',
                        message: 'Unit Anda belum pernah meminjam sarana dari ruangan lain atau gudang.',
                        action: (ref.watch(authStateProvider).user?.unit != null)
                            ? ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FormPeminjamanAsetScreen()));
                                },
                                icon: const Icon(LucideIcons.plus, size: 16),
                                label: const Text('Ajukan Peminjaman'),
                              )
                            : null,
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(daftarPeminjamanSayaProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return PeminjamanCardItem(
                      item: item,
                      onCancelTap: item.isDiajukan
                          ? () async {
                              final notifier = ref.read(peminjamanActionProvider.notifier);
                              final ok = await notifier.batalkanPeminjaman(item.id);
                              if (!context.mounted) return;
                              final state = ref.read(peminjamanActionProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok ? (state.successMessage ?? 'Dibatalkan') : (state.errorMessage ?? 'Gagal')),
                                  backgroundColor: ok ? AppColors.success : AppColors.danger,
                                ),
                              );
                            }
                          : null,
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
            error: (err, _) => Center(child: Text(err.toString(), style: const TextStyle(color: AppColors.danger))),
          ),

          // Tab 2: Otorisasi Masuk (Karu & Kagud)
          if (_canApprove)
            approvalPeminjamanAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(daftarApprovalPeminjamanProvider),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.65,
                        child: const EmptyStateView(
                          icon: LucideIcons.shieldCheck,
                          title: 'Tidak Ada Antrean Otorisasi',
                          message: 'Tidak ada permohonan peminjaman aset masuk yang memerlukan persetujuan saat ini.',
                        ),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(daftarApprovalPeminjamanProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final item = list[index];
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
                                  decoration: BoxDecoration(color: AppColors.tintVioletBg, borderRadius: BorderRadius.circular(8)),
                                  child: Text(item.kode, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryPurple)),
                                ),
                                StatusBadge(status: item.status),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(item.namaAset, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text('Kode: ${item.kodeAset} • Pemohon: ${item.unitPeminjam} (${item.pengaju})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('Jadwal: ${item.tanggalPinjam} s/d ${item.tanggalKembaliRencana}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            if (item.keperluan.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Keperluan: ${item.keperluan}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
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
                                      onPressed: () => _showOtorisasiModal(context, item, 'tolak'),
                                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFFCA5A5))),
                                      child: const Text('Tolak', style: TextStyle(color: AppColors.danger)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _showOtorisasiModal(context, item, 'setujui'),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
                                      child: const Text('Setujui Pinjam'),
                                    ),
                                  ),
                                ],
                              )
                            else if (item.isDisetujui)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showOtorisasiModal(context, item, 'serah_terima'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPurple, foregroundColor: Colors.white),
                                  icon: const Icon(LucideIcons.arrowRightLeft, size: 16),
                                  label: const Text('Serah Terima Fisik ke Peminjam'),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
              error: (err, _) => Center(child: Text(err.toString(), style: const TextStyle(color: AppColors.danger))),
            ),

          // Tab 3: Siap Pengembalian
          peminjamanAktifAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(daftarPeminjamanAktifDipinjamProvider),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.65,
                      child: const EmptyStateView(
                        icon: LucideIcons.packageCheck,
                        title: 'Tidak Ada Aset Dipinjam',
                        message: 'Unit Anda saat ini tidak memiliki tanggungan aset fisik yang sedang aktif dipinjam.',
                      ),
                    ),
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(daftarPeminjamanAktifDipinjamProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return PeminjamanCardItem(
                      item: item,
                      onReturnTap: () => _showReturnModal(context, item),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryPurple)),
            error: (err, _) => Center(child: Text(err.toString(), style: const TextStyle(color: AppColors.danger))),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tintVioletBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryPurple),
      ),
    );
  }
}
