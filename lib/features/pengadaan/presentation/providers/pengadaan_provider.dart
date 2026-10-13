import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../approval/presentation/providers/approval_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../gudang/presentation/providers/inbound_provider.dart';
import '../../data/models/master_barang_model.dart';
import '../../data/models/pr_model.dart';
import '../../data/models/po_model.dart';
import '../../data/repositories/pengadaan_repository.dart';

/// Menyediakan [PengadaanRepository] yang memakai [DioClient] bersama untuk seluruh panggilan API pengadaan.
final pengadaanRepositoryProvider = Provider<PengadaanRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return PengadaanRepository(client);
});

class KatalogBarangParams {
  final String query;
  final String? tipe;

  const KatalogBarangParams({this.query = '', this.tipe});

  /// Dua parameter dianggap sama bila query dan tipe sama, agar cache family provider tidak duplikat.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KatalogBarangParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          tipe == other.tipe;

  /// Hash dari query dan tipe, konsisten dengan operator `==` untuk kunci cache provider.
  @override
  int get hashCode => Object.hash(query, tipe);
}

/// Memuat katalog barang berdasarkan kata kunci dan tipe; otomatis dibuang saat tidak dipakai.
final katalogBarangProvider =
    FutureProvider.autoDispose.family<List<MasterBarangModel>, KatalogBarangParams>((ref, params) async {
  final repository = ref.watch(pengadaanRepositoryProvider);
  return await repository.getKatalogBarang(cari: params.query, tipe: params.tipe);
});

/// Memuat daftar PR untuk layar riwayat dan hub pengadaan.
final daftarPrProvider = FutureProvider.autoDispose<List<PrHeaderModel>>((ref) async {
  final repository = ref.watch(pengadaanRepositoryProvider);
  return await repository.getDaftarPr();
});

class PrSubmissionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const PrSubmissionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

class PrSubmissionNotifier extends StateNotifier<PrSubmissionState> {
  final PengadaanRepository _repository;
  final Ref _ref;

  /// Membuat notifier pengajuan PR dengan repository dan [Ref] untuk me-refresh provider terkait.
  PrSubmissionNotifier(this._repository, this._ref) : super(const PrSubmissionState());

  /// Mengajukan PR dari isi keranjang; mengembalikan true bila sukses.
  /// Jika pengaju Karu, PR langsung disetujui agar diteruskan ke Bagian Pengadaan tanpa antre approval.
  Future<bool> submitPr({
    int? unitId,
    int? gudangId,
    required String urgensi,
    String? catatan,
    required List<PrCartItemModel> items,
    bool isKaru = false,
  }) async {
    if (items.isEmpty) {
      state = const PrSubmissionState(
        errorMessage: 'Keranjang pengadaan masih kosong. Silakan pilih minimal 1 barang.',
      );
      return false;
    }

    state = const PrSubmissionState(isLoading: true);
    try {
      final payloadItems = items.map((e) => e.toSubmissionJson()).toList();
      final res = await _repository.submitPr(
        unitId: unitId,
        gudangId: gudangId,
        urgensi: urgensi,
        catatan: catatan,
        items: payloadItems,
        isKaru: isKaru,
      );
      final kode = res['kode']?.toString() ?? 'PR Baru';
      final prId = res['id'] is int ? res['id'] as int : int.tryParse(res['id']?.toString() ?? '');
      final currentStatus = res['status']?.toString().toUpperCase();

      // Jika diajukan oleh Karu dan backend masih berstatus DIAJUKAN, bypass approval langsung
      if (isKaru && prId != null && currentStatus == 'DIAJUKAN') {
        try {
          final approvalRepo = _ref.read(approvalRepositoryProvider);
          await approvalRepo.executeApprovalPr(id: prId, aksi: 'setujui');
        } catch (_) {
          // Abaikan jika sudah di-approve otomatis oleh backend
        }
      }

      state = PrSubmissionState(
        isLoading: false,
        successMessage: isKaru
            ? 'Permintaan pengadaan $kode berhasil diajukan dan langsung diteruskan ke Bagian Pengadaan.'
            : 'Permintaan pengadaan $kode berhasil diajukan.',
      );

      _ref.invalidate(daftarPrProvider);
      _ref.invalidate(dashboardSummaryProvider);
      _ref.invalidate(approvalPendingProvider);
      return true;
    } catch (e) {
      state = PrSubmissionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }
}

/// Provider state pengajuan PR yang diamati form pengajuan untuk loading, error, dan sukses.
final prSubmissionProvider =
    StateNotifierProvider<PrSubmissionNotifier, PrSubmissionState>((ref) {
  final repository = ref.watch(pengadaanRepositoryProvider);
  return PrSubmissionNotifier(repository, ref);
});

/// Memuat daftar pemasok aktif sebagai pilihan saat menerbitkan PO.
final pemasokListProvider = FutureProvider.autoDispose<List<PemasokOptionModel>>((ref) async {
  final repository = ref.watch(pengadaanRepositoryProvider);
  return repository.getDaftarPemasok();
});

/// Menyimpan filter status PO yang aktif; bawaan DITERBITKAN karena itu yang perlu ditindaklanjuti.
final poStatusFilterProvider = StateProvider.autoDispose<String>((ref) => 'DITERBITKAN');
/// Menyimpan kata kunci pencarian PO.
final poSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

/// Memuat daftar PO sesuai filter status dan pencarian; kosong bila pengguna belum login.
final poListProvider = FutureProvider.autoDispose<List<PesananPembelianModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (!authState.isAuthenticated || authState.user == null) {
    return const [];
  }
  final repository = ref.watch(pengadaanRepositoryProvider);
  final status = ref.watch(poStatusFilterProvider);
  final search = ref.watch(poSearchQueryProvider);

  return repository.getDaftarPo(
    status: status == 'SEMUA' ? null : status,
    search: search.isEmpty ? null : search,
  );
});

/// Menghitung PO berstatus DITERBITKAN yang masih perlu ditindaklanjuti (untuk badge); 0 bila belum login.
final poActionableCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (!authState.isAuthenticated || authState.user == null) {
    return 0;
  }
  final repository = ref.watch(pengadaanRepositoryProvider);
  final list = await repository.getDaftarPo(status: 'DITERBITKAN');
  return list.length;
});
class PoActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const PoActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

class PoActionNotifier extends StateNotifier<PoActionState> {
  final PengadaanRepository _repository;
  final Ref _ref;

  /// Membuat notifier aksi PO dengan repository dan [Ref] untuk me-refresh provider terkait.
  PoActionNotifier(this._repository, this._ref) : super(const PoActionState());

  /// Menerbitkan PO dari PR yang sudah diteruskan ke pengadaan; mengembalikan true bila sukses.
  /// Setelah sukses, daftar PO, PR, approval, inbound gudang, dan dashboard di-refresh agar data sinkron.
  Future<bool> terbitkanPo({
    required int prId,
    required int pemasokId,
    String? estimasiTanggalKirim,
    String syaratPembayaran = 'TEMPO_30_HARI',
    String? catatan,
    required List<Map<String, dynamic>> items,
  }) async {
    state = const PoActionState(isLoading: true);
    try {
      final res = await _repository.terbitkanPo(
        prId: prId,
        pemasokId: pemasokId,
        estimasiTanggalKirim: estimasiTanggalKirim,
        syaratPembayaran: syaratPembayaran,
        catatan: catatan,
        items: items,
      );
      final kode = res['kode']?.toString() ?? 'PO';
      state = PoActionState(
        isLoading: false,
        successMessage: 'Pesanan Pembelian $kode berhasil diterbitkan.',
      );
      _ref.invalidate(poListProvider);
      _ref.invalidate(poActionableCountProvider);
      _ref.invalidate(daftarPrProvider);
      _ref.invalidate(approvalPendingProvider);
      final user = _ref.read(authStateProvider).user;
      final canViewInbound = (user?.can('create_gudang_stok::penerimaan::po') ?? false) ||
          (user?.can('view_any_gudang_stok::penerimaan::po') ?? false) ||
          (user?.can('view_gudang_stok::penerimaan::po') ?? false) ||
          (user?.hasRole('petugas_gudang') ?? false) ||
          (user?.hasRole('kepala_gudang') ?? false) ||
          (user?.hasRole('admin_logistik') ?? false) ||
          (user?.isSuperAdmin ?? false);
      if (canViewInbound) {
        _ref.invalidate(daftarPoInboundProvider);
      }
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = PoActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  /// Mengubah status PO menjadi DIKIRIM_VENDOR; mengembalikan true bila sukses.
  /// Provider PO, inbound gudang, dan dashboard di-refresh agar tampilan terbaru.
  Future<bool> updateStatusKirim(int id, {String? estimasiTanggalKirim}) async {
    state = const PoActionState(isLoading: true);
    try {
      final res = await _repository.updateStatusKirim(
        id,
        estimasiTanggalKirim: estimasiTanggalKirim,
      );
      final kode = res['kode']?.toString() ?? 'PO';
      state = PoActionState(
        isLoading: false,
        successMessage: 'Status PO $kode berhasil diubah menjadi DIKIRIM_VENDOR.',
      );
      _ref.invalidate(poListProvider);
      _ref.invalidate(poActionableCountProvider);
      _ref.invalidate(daftarPoInboundProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = PoActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }
}

/// Provider state aksi PO (terbitkan dan kirim) yang diamati layar pengadaan.
final poActionProvider =
    StateNotifierProvider<PoActionNotifier, PoActionState>((ref) {
  final repository = ref.watch(pengadaanRepositoryProvider);
  return PoActionNotifier(repository, ref);
});
