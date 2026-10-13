import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../data/models/pengalihan_model.dart';
import '../../data/models/aset_tersedia_model.dart';
import '../../data/repositories/pengalihan_repository.dart';

/// Provider [PengalihanRepository] untuk operasi data pengalihan via klien HTTP bersama.
final pengalihanRepositoryProvider = Provider<PengalihanRepository>((ref) {
  final client = ref.watch(dioClientProvider);
  return PengalihanRepository(client);
});

/// Kategori pengalihan yang sedang dipilih ('ASET' atau 'BARANG'); default 'ASET'.
final selectedKategoriPengalihanProvider = StateProvider<String>((ref) => 'ASET');

/// Daftar pengalihan per [tab] (aktif/otorisasi/riwayat) sesuai kategori terpilih.
final daftarPengalihanProvider =
    FutureProvider.family.autoDispose<List<PengalihanItemModel>, String>((ref, tab) async {
  final repository = ref.watch(pengalihanRepositoryProvider);
  final kategori = ref.watch(selectedKategoriPengalihanProvider);
  return await repository.getDaftarPengalihan(tab: tab, tipe: kategori);
});

/// Jumlah pengalihan yang menunggu otorisasi pada kategori terpilih (untuk badge).
final countOtorisasiPengalihanProvider = FutureProvider.autoDispose<int>((ref) async {
  final repository = ref.watch(pengalihanRepositoryProvider);
  final kategori = ref.watch(selectedKategoriPengalihanProvider);
  final list = await repository.getDaftarPengalihan(tab: 'otorisasi', tipe: kategori);
  return list.length;
});

/// Daftar aset asal yang bisa dialihkan.
final daftarAsetAsalProvider = FutureProvider.autoDispose<List<AsetTersediaModel>>((ref) async {
  final repository = ref.watch(pengalihanRepositoryProvider);
  return await repository.getDaftarAsetAsal();
});

/// Stok barang tersedia pada gudang tertentu (berdasarkan barangId dan gudangId).
final stokTersediaGudangProvider =
    FutureProvider.family.autoDispose<int, ({int barangId, int gudangId})>((ref, arg) async {
  final repository = ref.watch(pengalihanRepositoryProvider);
  return await repository.getStokTersedia(barangId: arg.barangId, gudangId: arg.gudangId);
});

/// State aksi pengalihan: status loading serta pesan error/sukses.
class PengalihanActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  /// Membuat state aksi pengalihan; default idle tanpa pesan.
  const PengalihanActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

/// Notifier aksi pengalihan: ajukan, otorisasi, serah terima, dan batal.
class PengalihanActionNotifier extends StateNotifier<PengalihanActionState> {
  final PengalihanRepository _repository;
  final Ref _ref;

  /// Membuat notifier dengan repository pengalihan dan [Ref] untuk invalidasi provider terkait.
  PengalihanActionNotifier(this._repository, this._ref)
      : super(const PengalihanActionState());

  /// Mengajukan pengalihan aset dengan [payload]; sukses menyegarkan daftar pengalihan.
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

  /// Mengajukan pengalihan barang dengan [payload]; sukses menyegarkan daftar pengalihan.
  Future<bool> ajukanPengalihanBarang(Map<String, dynamic> payload) async {
    state = const PengalihanActionState(isLoading: true);
    try {
      final res = await _repository.submitPengalihanBarang(payload);
      final kode = res['kode']?.toString() ?? 'Pengalihan';
      state = PengalihanActionState(
        isLoading: false,
        successMessage: 'Pengalihan barang $kode berhasil diajukan.',
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

  /// Menyetujui atau menolak pengalihan [id] sesuai [aksi] (APPROVE/tolak) beserta [catatan].
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

  /// Menyelesaikan serah terima fisik pengalihan [id] dengan [kondisi] barang/aset (status menjadi SELESAI).
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

  /// Membatalkan pengalihan [id] dengan [alasan] opsional.
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
  /// Meng-invalidate semua daftar pengalihan, hitungan otorisasi, dan ringkasan dashboard agar dimuat ulang.
  void _invalidateLists() {
    _ref.invalidate(daftarPengalihanProvider('aktif'));
    _ref.invalidate(daftarPengalihanProvider('otorisasi'));
    _ref.invalidate(daftarPengalihanProvider('riwayat'));
    _ref.invalidate(countOtorisasiPengalihanProvider);
    _ref.invalidate(dashboardSummaryProvider);
  }
}

/// Provider [PengalihanActionNotifier] untuk aksi pengalihan aset/barang.
final pengalihanActionProvider =
    StateNotifierProvider<PengalihanActionNotifier, PengalihanActionState>((ref) {
  final repository = ref.watch(pengalihanRepositoryProvider);
  return PengalihanActionNotifier(repository, ref);
});
