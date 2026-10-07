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

final selectedKategoriPengalihanProvider = StateProvider<String>((ref) => 'ASET');

final daftarPengalihanProvider =
    FutureProvider.family.autoDispose<List<PengalihanItemModel>, String>((ref, tab) async {
  final repository = ref.watch(pengalihanRepositoryProvider);
  final kategori = ref.watch(selectedKategoriPengalihanProvider);
  return await repository.getDaftarPengalihan(tab: tab, tipe: kategori);
});

final countOtorisasiPengalihanProvider = FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.watch(pengalihanRepositoryProvider);
  final kategori = ref.watch(selectedKategoriPengalihanProvider);
  final list = await repository.getDaftarPengalihan(tab: 'otorisasi', tipe: kategori);
  return list.length;
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
    String tipe = 'ASET',
  }) async {
    state = const PengalihanActionState(isLoading: true);
    try {
      await _repository.otorisasiPengalihan(
        id: id,
        aksi: aksi,
        catatan: catatan,
        tipe: tipe,
      );
      state = PengalihanActionState(
        isLoading: false,
        successMessage: aksi == 'APPROVE'
            ? 'Pengalihan berhasil disetujui.'
            : 'Pengalihan berhasil ditolak.',
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
    String tipe = 'ASET',
  }) async {
    state = const PengalihanActionState(isLoading: true);
    try {
      await _repository.serahTerimaPengalihan(id: id, kondisi: kondisi, tipe: tipe);
      state = const PengalihanActionState(
        isLoading: false,
        successMessage: 'Serah terima fisik berhasil diselesaikan (Status: SELESAI).',
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
    String tipe = 'ASET',
  }) async {
    state = const PengalihanActionState(isLoading: true);
    try {
      await _repository.batalPengalihan(id: id, alasan: alasan, tipe: tipe);
      state = const PengalihanActionState(
        isLoading: false,
        successMessage: 'Pengalihan berhasil dibatalkan.',
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
    _ref.invalidate(countOtorisasiPengalihanProvider);
    _ref.invalidate(dashboardSummaryProvider);
  }
}

final pengalihanActionProvider =
    StateNotifierProvider<PengalihanActionNotifier, PengalihanActionState>((ref) {
  final repository = ref.watch(pengalihanRepositoryProvider);
  return PengalihanActionNotifier(repository, ref);
});
