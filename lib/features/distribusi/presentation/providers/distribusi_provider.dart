import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../gudang/presentation/providers/gudang_provider.dart';
import '../../../master/presentation/providers/register_aset_provider.dart';
import '../../../aset/presentation/providers/peminjaman_provider.dart';
import '../../data/models/amprah_model.dart';
import '../../data/models/sppb_model.dart';
import '../../data/repositories/distribusi_repository.dart';

/// Menyediakan instance [DistribusiRepository] yang memakai [DioClient] bersama.
final distribusiRepositoryProvider = Provider<DistribusiRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return DistribusiRepository(client);
});

/// Memuat katalog barang amprah berdasarkan kata kunci pencarian [query]; otomatis dibuang saat tidak dipakai.
final katalogAmprahProvider =
    FutureProvider.autoDispose.family<List<BarangAmprahKatalogModel>, String>((ref, query) async {
  final repository = ref.watch(distribusiRepositoryProvider);
  return await repository.getKatalogBarang(cari: query);
});

class AmprahFilterParams {
  final String status;
  final String urgensi;

  /// Membuat parameter filter daftar amprah; default "SEMUA" berarti tanpa filter.
  const AmprahFilterParams({
    this.status = 'SEMUA',
    this.urgensi = 'SEMUA',
  });

  /// Membandingkan parameter berdasarkan nilai status dan urgensi agar cache family provider tepat sasaran.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AmprahFilterParams &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          urgensi == other.urgensi;

  /// Hash konsisten dengan operator `==` supaya filter yang sama memakai cache provider yang sama.
  @override
  int get hashCode => status.hashCode ^ urgensi.hashCode;
}

/// Memuat daftar amprah ruangan sesuai filter status dan urgensi pada [AmprahFilterParams].
final daftarAmprahProvider =
    FutureProvider.autoDispose.family<List<AmprahHeaderModel>, AmprahFilterParams>((ref, params) async {
  final repository = ref.watch(distribusiRepositoryProvider);
  return await repository.getDaftarAmprah(
    status: params.status,
    urgensi: params.urgensi,
  );
});

/// Memuat rincian satu amprah berdasarkan ID.
final detailAmprahProvider =
    FutureProvider.autoDispose.family<AmprahHeaderModel, int>((ref, id) async {
  final repository = ref.watch(distribusiRepositoryProvider);
  return await repository.getDetailAmprah(id);
});

/// Memuat antrean picking gudang; mengembalikan daftar kosong bila user tidak punya izin/peran gudang agar tidak memicu 403.
final antreanPickingProvider =
    FutureProvider.autoDispose<List<PickingAntreanModel>>((ref) async {
  final user = ref.watch(authStateProvider).user;
  final canPick = (user?.can('create_gudang_stok::picking::distribusi') ?? false) ||
      (user?.can('update_gudang_stok::picking::distribusi') ?? false) ||
      (user?.can('view_any_gudang_stok::picking::distribusi') ?? false) ||
      (user?.hasRole('petugas_gudang') ?? false) ||
      (user?.hasRole('kepala_gudang') ?? false) ||
      (user?.hasRole('admin_logistik') ?? false) ||
      (user?.isSuperAdmin ?? false);

  if (!canPick) {
    return [];
  }

  final repository = ref.watch(distribusiRepositoryProvider);
  return await repository.getAntreanPicking();
});

/// Memuat daftar SPPB kiriman gudang yang menunggu diterima unit ruangan.
final sppbInboundProvider =
    FutureProvider.autoDispose<List<SppbHeaderModel>>((ref) async {
  final repository = ref.watch(distribusiRepositoryProvider);
  return await repository.getSppbInbound();
});

class AmprahActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  /// Membuat state aksi amprah; default tidak sedang loading dan tanpa pesan.
  const AmprahActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

class AmprahActionNotifier extends StateNotifier<AmprahActionState> {
  final DistribusiRepository _repository;
  final Ref _ref;

  /// Membuat notifier aksi amprah dengan repository untuk API dan [Ref] untuk me-refresh provider terkait.
  AmprahActionNotifier(this._repository, this._ref) : super(const AmprahActionState());

  /// Memvalidasi keranjang (tidak kosong, stok cukup) lalu mengajukan amprah; true bila berhasil, dan me-refresh daftar amprah, approval, dan dashboard.
  Future<bool> submitAmprah({
    int? gudangId,
    required String urgensi,
    String? catatan,
    required List<AmprahCartDraftItem> items,
  }) async {
    if (items.isEmpty) {
      state = const AmprahActionState(
        errorMessage: 'Keranjang amprah masih kosong. Pilih minimal 1 barang.',
      );
      return false;
    }

    for (final item in items) {
      if (item.barang.stokTersedia <= 0) {
        state = AmprahActionState(
          errorMessage: 'Komoditas "${item.barang.nama}" di gudang saat ini kosong (0). Hapus barang ini sebelum mengirim.',
        );
        return false;
      }
      if (item.jumlah > item.barang.stokTersedia) {
        state = AmprahActionState(
          errorMessage: 'Jumlah diminta untuk "${item.barang.nama}" (${item.jumlah} ${item.barang.satuan}) melebihi stok gudang yang tersedia (${item.barang.stokTersedia} ${item.barang.satuan}).',
        );
        return false;
      }
    }

    state = const AmprahActionState(isLoading: true);
    try {
      final payload = items.map((e) => e.toSubmissionJson()).toList();
      final res = await _repository.submitAmprah(
        gudangId: gudangId,
        urgensi: urgensi,
        catatan: catatan,
        items: payload,
      );

      final kode = res['kode']?.toString() ?? 'REQ';
      state = AmprahActionState(
        isLoading: false,
        successMessage: 'Permintaan amprah $kode berhasil diajukan.',
      );

      _ref.invalidate(daftarAmprahProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = AmprahActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  /// Membatalkan amprah [id] lalu me-refresh daftar amprah, approval, dan dashboard; true bila berhasil.
  Future<bool> batalkanAmprah(int id) async {
    state = const AmprahActionState(isLoading: true);
    try {
      await _repository.batalAmprah(id);
      state = const AmprahActionState(
        isLoading: false,
        successMessage: 'Permintaan amprah berhasil dibatalkan.',
      );

      _ref.invalidate(daftarAmprahProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = AmprahActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  /// Menjalankan picking FEFO untuk permintaan [permintaanId] dan me-refresh antrean, SPPB, rak, dan dashboard; true bila berhasil.
  Future<bool> eksekusiPicking(int permintaanId) async {
    state = const AmprahActionState(isLoading: true);
    try {
      final res = await _repository.eksekusiPicking(permintaanId);
      final sppbKode = res['sppb_kode']?.toString() ?? 'SPPB';
      state = AmprahActionState(
        isLoading: false,
        successMessage: 'Picking FEFO berhasil. Dokumen $sppbKode telah diterbitkan.',
      );

      _ref.invalidate(antreanPickingProvider);
      _ref.invalidate(sppbInboundProvider);
      _ref.invalidate(daftarRakProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = AmprahActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  /// Mengonfirmasi penerimaan SPPB [sppbId] sehingga stok ruangan bertambah, lalu me-refresh data terkait; true bila berhasil.
  Future<bool> konfirmasiTerimaSppb(int sppbId) async {
    state = const AmprahActionState(isLoading: true);
    try {
      final res = await _repository.konfirmasiTerimaSppb(sppbId);
      final rcvKode = res['kode_rcv']?.toString() ?? 'RCV';
      state = AmprahActionState(
        isLoading: false,
        successMessage: 'Barang berhasil diterima & masuk stok ruangan ($rcvKode).',
      );

      _ref.invalidate(sppbInboundProvider);
      _ref.invalidate(daftarAmprahProvider);
      _ref.invalidate(registerAsetListProvider);
      _ref.invalidate(daftarPeminjamanSayaProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = AmprahActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  /// Menyetujui atau menolak amprah [id] (Meja 1 Karu / Meja 2 gudang) lalu me-refresh daftar amprah, approval, dan dashboard; true bila berhasil.
  Future<bool> approveAmprah({
    required int id,
    required bool isSetujui,
    String? catatan,
  }) async {
    state = const AmprahActionState(isLoading: true);
    try {
      await _repository.approveAmprah(id: id, isSetujui: isSetujui, catatan: catatan);
      state = AmprahActionState(
        isLoading: false,
        successMessage: isSetujui
            ? 'Amprah Ruangan berhasil disetujui.'
            : 'Amprah Ruangan berhasil ditolak.',
      );

      _ref.invalidate(daftarAmprahProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = AmprahActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }
}

/// Menyediakan [AmprahActionNotifier] untuk aksi tulis amprah (ajukan, batal, picking, terima SPPB) beserta state loading/pesannya.
final amprahActionProvider =
    StateNotifierProvider<AmprahActionNotifier, AmprahActionState>((ref) {
  final repository = ref.watch(distribusiRepositoryProvider);
  return AmprahActionNotifier(repository, ref);
});
