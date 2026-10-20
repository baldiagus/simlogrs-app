import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_error_view.dart';
import '../../../../shared/widgets/app_loading_view.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/pengalihan_model.dart';
import '../providers/pengalihan_provider.dart';
import '../utils/pengalihan_access.dart';
import '../widgets/modal_pengalihan_aset_sheet.dart';
import '../widgets/modal_pengalihan_barang_sheet.dart';
import '../widgets/pengalihan_card_item.dart';
import '../widgets/pengalihan_empty_tab.dart';

/// Halaman hub pengalihan aset dan barang gudang.
class PengalihanHubScreen extends ConsumerStatefulWidget {
  /// Membuat layar hub pengalihan.
  const PengalihanHubScreen({super.key});

  /// Membuat state layar hub pengalihan.
  @override
  ConsumerState<PengalihanHubScreen> createState() =>
      _PengalihanHubScreenState();
}

/// State hub pengalihan: mengelola tab, hak otorisasi, dan alur pengajuan.
class _PengalihanHubScreenState extends ConsumerState<PengalihanHubScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _canApprove = false;

  /// Menentukan hak otorisasi awal dan membuat [TabController] sesuai jumlah tab.
  @override
  void initState() {
    super.initState();
    _canApprove =
        hasOtorisasiPengalihanAccess(ref.read(authStateProvider).user);
    _tabController = TabController(length: _canApprove ? 3 : 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final user = ref.read(authStateProvider).user;
      if (!canAccessPengalihanBarang(user)) {
        ref.read(selectedKategoriPengalihanProvider.notifier).state = 'ASET';
      }
    });
  }

  /// Membuang [TabController] saat state dilepas agar tidak bocor memori.
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Membuka modal pengajuan pengalihan aset; segarkan data bila berhasil.
  void _openCreateAsetFlow() {
    ModalPengalihanAsetSheet.show(context).then((ok) {
      if (ok == true) {
        _refreshAll();
      }
    });
  }

  /// Membuka modal pengajuan pengalihan barang gudang; segarkan data bila berhasil.
  void _openCreateBarangFlow() {
    ModalPengalihanBarangSheet.show(context).then((ok) {
      if (ok == true) {
        _refreshAll();
      }
    });
  }

  /// Menyegarkan semua daftar pengalihan dan jumlah otorisasi.
  void _refreshAll() {
    ref.invalidate(daftarPengalihanProvider('aktif'));
    ref.invalidate(daftarPengalihanProvider('otorisasi'));
    ref.invalidate(daftarPengalihanProvider('riwayat'));
    ref.invalidate(countOtorisasiPengalihanProvider);
  }

  /// Membangun halaman hub pengalihan: tab Aktif/Otorisasi/Riwayat, FAB ajukan, dan pemilih kategori.
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final canApproveNow = hasOtorisasiPengalihanAccess(user);

    if (canApproveNow != _canApprove) {
      _canApprove = canApproveNow;
      _tabController.dispose();
      _tabController = TabController(length: _canApprove ? 3 : 2, vsync: this);
    }

    final countOtorisasi =
        ref.watch(countOtorisasiPengalihanProvider).valueOrNull ?? 0;
    final canBarang = canAccessPengalihanBarang(user);
    final selectedKategori = canBarang
        ? ref.watch(selectedKategoriPengalihanProvider)
        : 'ASET';
    final isAset = selectedKategori == 'ASET';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(isAset ? 'Pengalihan Aset RS' : 'Pengalihan Barang Gudang'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            tooltip: 'Segarkan',
            onPressed: _refreshAll,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          indicatorColor: AppColors.primaryPurple,
          indicatorWeight: 3,
          labelColor: AppColors.primaryPurple,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            const Tab(text: 'Aktif'),
            if (_canApprove)
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Flexible(
                      child: Text('Otorisasi',
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    if (countOtorisasi > 0) ...[
                      const SizedBox(width: 4),
                      _buildBadge(countOtorisasi),
                    ],
                  ],
                ),
              ),
            const Tab(text: 'Riwayat'),
          ],
        ),
      ),
      floatingActionButton: !canCreatePengalihan(user, selectedKategori)
          ? null
          : FloatingActionButton.extended(
              heroTag: null,
              key: Key(
                  'fab_ajukan_pengalihan_${selectedKategori.toLowerCase()}'),
              onPressed: isAset ? _openCreateAsetFlow : _openCreateBarangFlow,
              backgroundColor:
                  isAset ? AppColors.primaryPurple : AppColors.tintBlue,
              foregroundColor: Colors.white,
              icon: const Icon(LucideIcons.plus, size: 18),
              label: Text(
                isAset ? 'Ajukan Pengalihan Aset' : 'Ajukan Pengalihan Barang',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
      body: Column(
        children: [
          if (canBarang) _buildKategoriSelector(selectedKategori),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent('aktif', countOtorisasi),
                if (_canApprove) _buildTabContent('otorisasi', countOtorisasi),
                _buildTabContent('riwayat', countOtorisasi),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Membangun pemilih kategori pengalihan (Aset Fisik / Barang Gudang).
  Widget _buildKategoriSelector(String selectedKategori) {
    /// Chip pilihan kategori: aktif bila sama dengan kategori terpilih.
    Widget chip(String label, String kategori) => Expanded(
          child: ChoiceChip(
            label: Center(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            selected: selectedKategori == kategori,
            onSelected: (val) {
              if (val) {
                ref.read(selectedKategoriPengalihanProvider.notifier).state =
                    kategori;
              }
            },
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      color: AppColors.surface,
      child: Row(
        children: [
          chip('Aset Fisik', 'ASET'),
          const SizedBox(width: 8),
          chip('Barang Gudang', 'BARANG'),
        ],
      ),
    );
  }

  /// Membangun badge jumlah otorisasi; kosong bila jumlah 0.
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
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryPurple),
      ),
    );
  }

  /// Membangun isi tab: daftar pengalihan, tampilan kosong, loading, atau error.
  Widget _buildTabContent(String tab, int countOtorisasi) {
    final user = ref.watch(authStateProvider).user;
    final canBarang = canAccessPengalihanBarang(user);
    final selectedKategori = canBarang
        ? ref.watch(selectedKategoriPengalihanProvider)
        : 'ASET';
    final isAset = selectedKategori == 'ASET';
    final asyncData = ref.watch(daftarPengalihanProvider(tab));
    return asyncData.when(
      data: (list) {
        if (list.isEmpty) {
          return PengalihanEmptyTab(
            tab: tab,
            countOtorisasi: countOtorisasi,
            isAset: isAset,
            canCreate: canCreatePengalihan(user, selectedKategori),
            onRefresh: () async =>
                ref.invalidate(daftarPengalihanProvider(tab)),
            onBukaOtorisasi: () => _tabController.animateTo(1),
            onCreate: isAset ? _openCreateAsetFlow : _openCreateBarangFlow,
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(daftarPengalihanProvider(tab)),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: list.length,
            itemBuilder: (context, index) =>
                _buildPengalihanCard(list[index], tab),
          ),
        );
      },
      loading: () =>
          const AppLoadingView(message: 'Memuat data pengalihan aset...'),
      error: (err, _) => AppErrorView(
        error: err.toString().replaceAll('ApiException: ', ''),
        onRetry: () => ref.invalidate(daftarPengalihanProvider(tab)),
      ),
    );
  }

  /// Menjalankan aksi pengalihan lalu menampilkan toast sukses bila berhasil.
  Future<void> _runAction(
      Future<bool> Function(PengalihanActionNotifier n) action,
      String successMessage) async {
    final ok = await action(ref.read(pengalihanActionProvider.notifier));
    if (ok && mounted) {
      AppToast.success(context, successMessage);
    }
  }

  /// Membangun kartu pengalihan beserta aksi batal, tolak, setuju, dan serah terima.
  Widget _buildPengalihanCard(PengalihanItemModel item, String tab) {
    return PengalihanCardItem(
      item: item,
      tab: tab,
      onCancelTap: () => _runAction(
        (n) => n.batalPengalihan(id: item.id, tipe: item.tipe),
        'Pengalihan berhasil dibatalkan',
      ),
      onRejectTap: () => _runAction(
        (n) =>
            n.otorisasiPengalihan(id: item.id, aksi: 'REJECT', tipe: item.tipe),
        'Pengalihan berhasil ditolak',
      ),
      onApproveTap: () => _runAction(
        (n) => n.otorisasiPengalihan(
            id: item.id, aksi: 'APPROVE', tipe: item.tipe),
        'Pengalihan berhasil disetujui',
      ),
      onReceiveTap: () => _runAction(
        (n) => n.serahTerimaPengalihan(id: item.id, tipe: item.tipe),
        'Serah terima fisik selesai. Mutasi resmi dibukukan.',
      ),
    );
  }
}
