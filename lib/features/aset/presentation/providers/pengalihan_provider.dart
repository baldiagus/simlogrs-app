import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/models/pengalihan_model.dart';
import '../../data/repositories/pengalihan_repository.dart';

final pengalihanRepositoryProvider = Provider<PengalihanRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return PengalihanRepository(client);
});

final daftarPengalihanProvider =
    FutureProvider.family.autoDispose<List<PengalihanItemModel>, String>((ref, tab) async {
  final repository = ref.watch(pengalihanRepositoryProvider);
  return await repository.getDaftarPengalihan(tab: tab);
});

class PengalihanActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const PengalihanActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

class PengalihanActionNotifier extends StateNotifier<PengalihanActionState> {
  final PengalihanRepository _repository;
  final Ref _ref;

  PengalihanActionNotifier(this._repository, this._ref)
      : super(const PengalihanActionState());

  Future<bool> ajukanPengalihan(Map<String, dynamic> payload) async {
    state = const PengalihanActionState(isLoading: true);
    try {
      final res = await _repository.submitPengalihan(payload);
      final kode = res['kode']?.toString() ?? 'Pengalihan';
      state = PengalihanActionState(
        isLoading: false,
        successMessage: 'Pengalihan aset $kode berhasil diajukan.',
      );
      _invalidateLists();
      return true;
    } catch (e) {
      state = PengalihanActionState(
        isLoading: false,
        errorMessage: e is ApiException ? e.message : e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  Future<bool> otorisasiPengalihan({
    required int id,
    required String aksi,
    String? catatan,
  }) async {
    state = const PengalihanActionState(isLoading: true);
    try {
      await _repository.otorisasiPengalihan(
        id: id,
        aksi: aksi,
        catatan: catatan,
      );
      state = PengalihanActionState(
        isLoading: false,
        successMessage: aksi == 'APPROVE'
            ? 'Pengalihan aset berhasil disetujui.'
            : 'Pengalihan aset berhasil ditolak.',
      );
      _invalidateLists();
      return true;
    } catch (e) {
      state = PengalihanActionState(
        isLoading: false,
        errorMessage: e is ApiException ? e.message : e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  Future<bool> serahTerimaPengalihan({
    required int id,
    String kondisi = 'BAIK',
  }) async {
    state = const PengalihanActionState(isLoading: true);
    try {
      await _repository.serahTerimaPengalihan(id: id, kondisi: kondisi);
      state = const PengalihanActionState(
        isLoading: false,
        successMessage: 'Serah terima fisik aset berhasil diselesaikan (Status: SELESAI).',
      );
      _invalidateLists();
      return true;
    } catch (e) {
      state = PengalihanActionState(
        isLoading: false,
        errorMessage: e is ApiException ? e.message : e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  Future<bool> batalPengalihan({
    required int id,
    String? alasan,
  }) async {
    state = const PengalihanActionState(isLoading: true);
    try {
      await _repository.batalPengalihan(id: id, alasan: alasan);
      state = const PengalihanActionState(
        isLoading: false,
        successMessage: 'Pengalihan aset berhasil dibatalkan.',
      );
      _invalidateLists();
      return true;
    } catch (e) {
      state = PengalihanActionState(
        isLoading: false,
        errorMessage: e is ApiException ? e.message : e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  void _invalidateLists() {
    _ref.invalidate(daftarPengalihanProvider('aktif'));
    _ref.invalidate(daftarPengalihanProvider('otorisasi'));
    _ref.invalidate(daftarPengalihanProvider('riwayat'));
    _ref.invalidate(dashboardSummaryProvider);
  }
}

final pengalihanActionProvider =
    StateNotifierProvider<PengalihanActionNotifier, PengalihanActionState>((ref) {
  final repository = ref.watch(pengalihanRepositoryProvider);
  return PengalihanActionNotifier(repository, ref);
});
