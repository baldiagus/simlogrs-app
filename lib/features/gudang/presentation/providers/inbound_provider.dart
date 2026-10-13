import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../pengadaan/presentation/providers/pengadaan_provider.dart';
import '../../data/models/po_inbound_model.dart';
import '../../data/repositories/gudang_repository.dart';
import 'gudang_provider.dart';

/// Daftar PO yang siap diterima (inbound). Kosong bila user tidak punya izin/peran penerimaan gudang.
final daftarPoInboundProvider =
    FutureProvider.autoDispose<List<PoInboundHeaderModel>>((ref) async {
  final user = ref.watch(authStateProvider).user;
  final canView = (user?.can('create_gudang_stok::penerimaan::po') ?? false) ||
      (user?.can('view_any_gudang_stok::penerimaan::po') ?? false) ||
      (user?.can('view_gudang_stok::penerimaan::po') ?? false) ||
      (user?.hasRole('petugas_gudang') ?? false) ||
      (user?.hasRole('kepala_gudang') ?? false) ||
      (user?.hasRole('admin_logistik') ?? false) ||
      (user?.isSuperAdmin ?? false);

  if (!canView) {
    return [];
  }

  final repository = ref.watch(gudangRepositoryProvider);
  return await repository.getPoInboundList();
});

/// State aksi penerimaan/penolakan inbound: status loading plus pesan error/sukses untuk UI.
class InboundActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const InboundActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

/// Notifier aksi inbound: validasi, kirim penerimaan atau penolakan PO ke API, lalu segarkan data terkait.
class InboundActionNotifier extends StateNotifier<InboundActionState> {
  final GudangRepository _repository;
  final Ref _ref;

  /// Membuat notifier dengan repository gudang dan [Ref] untuk invalidasi provider lain.
  InboundActionNotifier(this._repository, this._ref)
      : super(const InboundActionState());

  /// Validasi draft item lalu catat penerimaan PO ke stok gudang. Return true bila sukses,
  /// dan meng-invalidate daftar PO, rak, PR, serta ringkasan dashboard.
  Future<bool> submitPenerimaan({
    required int poId,
    required String nomorSuratJalan,
    String? catatan,
    required List<InboundItemDraft> items,
  }) async {
    final validItems = items.where((i) => i.jumlahDiterima > 0).toList();
    if (validItems.isEmpty) {
      state = const InboundActionState(
        errorMessage: 'Minimal satu barang harus memiliki kuantitas diterima > 0.',
      );
      return false;
    }

    for (final item in validItems) {
      if (item.lokasiGudangId == null) {
        state = InboundActionState(
          errorMessage: 'Pilih rak penyimpanan untuk barang "${item.poItem.namaBarang}".',
        );
        return false;
      }
      if (item.nomorBatch.trim().isEmpty) {
        state = InboundActionState(
          errorMessage: 'Nomor batch untuk "${item.poItem.namaBarang}" wajib diisi.',
        );
        return false;
      }
    }

    state = const InboundActionState(isLoading: true);
    try {
      final payload = validItems.map((e) => e.toJson()).toList();
      final res = await _repository.submitPenerimaanPo(
        poId: poId,
        nomorSuratJalan: nomorSuratJalan.trim(),
        catatan: catatan?.trim(),
        items: payload,
      );

      final kodeRcv = res['kode_rcv']?.toString() ?? 'Penerimaan';
      state = InboundActionState(
        isLoading: false,
        successMessage: 'Penerimaan $kodeRcv berhasil dicatat ke stok gudang.',
      );

      _ref.invalidate(daftarPoInboundProvider);
      _ref.invalidate(daftarRakProvider);
      _ref.invalidate(daftarPrProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = InboundActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  /// Tolak kiriman fisik PO beserta alasan penolakan. Return true bila sukses dan menyegarkan daftar PO.
  Future<bool> tolakPenerimaan({
    required int poId,
    required String nomorSuratJalan,
    required String alasanPenolakan,
    required List<Map<String, dynamic>> items,
  }) async {
    state = const InboundActionState(isLoading: true);
    try {
      final res = await _repository.tolakPenerimaanPo(
        poId: poId,
        nomorSuratJalan: nomorSuratJalan.trim(),
        alasanPenolakan: alasanPenolakan.trim(),
        items: items,
      );

      final nomorDokumen = res['nomor_dokumen']?.toString() ?? 'Penolakan';
      state = InboundActionState(
        isLoading: false,
        successMessage: 'Kiriman fisik berhasil ditolak ($nomorDokumen).',
      );

      _ref.invalidate(daftarPoInboundProvider);
      return true;
    } catch (e) {
      state = InboundActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }
}

/// Provider notifier aksi inbound yang dipakai form penerimaan dan modal penolakan.
final inboundActionProvider =
    StateNotifierProvider<InboundActionNotifier, InboundActionState>((ref) {
  final repository = ref.watch(gudangRepositoryProvider);
  return InboundActionNotifier(repository, ref);
});
