import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../approval/presentation/providers/approval_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/models/master_barang_model.dart';
import '../../data/models/pr_model.dart';
import '../../data/models/po_model.dart';
import '../../data/repositories/pengadaan_repository.dart';

final pengadaanRepositoryProvider = Provider<PengadaanRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return PengadaanRepository(client);
});

class KatalogBarangParams {
  final String query;
  final String? tipe;

  const KatalogBarangParams({this.query = '', this.tipe});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KatalogBarangParams &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          tipe == other.tipe;

  @override
  int get hashCode => Object.hash(query, tipe);
}

final katalogBarangProvider =
    FutureProvider.autoDispose.family<List<MasterBarangModel>, KatalogBarangParams>((ref, params) async {
  final repository = ref.watch(pengadaanRepositoryProvider);
  return await repository.getKatalogBarang(cari: params.query, tipe: params.tipe);
});

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

  PrSubmissionNotifier(this._repository, this._ref) : super(const PrSubmissionState());

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

final prSubmissionProvider =
    StateNotifierProvider<PrSubmissionNotifier, PrSubmissionState>((ref) {
  final repository = ref.watch(pengadaanRepositoryProvider);
  return PrSubmissionNotifier(repository, ref);
});

final pemasokListProvider = FutureProvider.autoDispose<List<PemasokOptionModel>>((ref) async {
  final repository = ref.watch(pengadaanRepositoryProvider);
  return repository.getDaftarPemasok();
});

final poStatusFilterProvider = StateProvider.autoDispose<String>((ref) => 'SEMUA');
final poSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

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

  PoActionNotifier(this._repository, this._ref) : super(const PoActionState());

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
      _ref.invalidate(daftarPrProvider);
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

final poActionProvider =
    StateNotifierProvider<PoActionNotifier, PoActionState>((ref) {
  final repository = ref.watch(pengadaanRepositoryProvider);
  return PoActionNotifier(repository, ref);
});
