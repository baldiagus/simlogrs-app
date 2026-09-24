import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/models/po_inbound_model.dart';
import '../../data/repositories/gudang_repository.dart';
import 'gudang_provider.dart';

final daftarPoInboundProvider =
    FutureProvider.autoDispose<List<PoInboundHeaderModel>>((ref) async {
  final repository = ref.watch(gudangRepositoryProvider);
  return await repository.getPoInboundList();
});

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

class InboundActionNotifier extends StateNotifier<InboundActionState> {
  final GudangRepository _repository;
  final Ref _ref;

  InboundActionNotifier(this._repository, this._ref)
      : super(const InboundActionState());

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
}

final inboundActionProvider =
    StateNotifierProvider<InboundActionNotifier, InboundActionState>((ref) {
  final repository = ref.watch(gudangRepositoryProvider);
  return InboundActionNotifier(repository, ref);
});
