import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/aset_tersedia_model.dart';
import '../../data/models/peminjaman_aset_model.dart';
import '../../data/repositories/aset_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../master/presentation/providers/register_aset_provider.dart';
import 'aset_provider.dart';
final katalogAsetTersediaProvider =
    FutureProvider.autoDispose.family<List<AsetTersediaModel>, String>((ref, query) async {
  final repository = ref.watch(asetRepositoryProvider);
  return await repository.getKatalogTersedia(cari: query);
});

final katalogAsetPengalihanProvider =
    FutureProvider.autoDispose.family<List<AsetTersediaModel>, String>((ref, query) async {
  final repository = ref.watch(asetRepositoryProvider);
  return await repository.getKatalogTersedia(cari: query, tujuan: 'pengalihan');
});

final daftarPeminjamanSayaProvider =
    FutureProvider.autoDispose<List<PeminjamanAsetModel>>((ref) async {
  final repository = ref.watch(asetRepositoryProvider);
  return await repository.getDaftarPeminjaman(perspektif: 'peminjam');
});

final daftarPeminjamanAktifDipinjamProvider =
    FutureProvider.autoDispose<List<PeminjamanAsetModel>>((ref) async {
  final repository = ref.watch(asetRepositoryProvider);
  final all = await repository.getDaftarPeminjaman(perspektif: 'peminjam');
  return all.where((item) => item.status == 'DIPINJAM').toList();
});

final daftarPeminjamanAktifDipinjamkanProvider =
    FutureProvider.autoDispose<List<PeminjamanAsetModel>>((ref) async {
  final repository = ref.watch(asetRepositoryProvider);
  final all = await repository.getDaftarPeminjaman(perspektif: 'penyedia');
  return all.where((item) => item.status == 'DIPINJAM').toList();
});

final daftarApprovalPeminjamanProvider =
    FutureProvider.autoDispose<List<ApprovalPeminjamanModel>>((ref) async {
  final user = ref.watch(authStateProvider).user;
  final canApprove = (user?.can('update_layanan_unit::approval::peminjaman') ?? false) ||
      (user?.can('layanan_unit::approval::peminjaman') ?? false) ||
      (user?.hasRole('kepala_unit') ?? false) ||
      (user?.hasRole('kepala_gudang') ?? false) ||
      (user?.hasRole('kepala_teknisi') ?? false) ||
      (user?.hasRole('admin_logistik') ?? false) ||
      (user?.hasRole('super_admin') ?? false);

  if (!canApprove) {
    return [];
  }

  final repository = ref.watch(asetRepositoryProvider);
  return await repository.getDaftarApprovalPeminjaman();
});

class PeminjamanActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const PeminjamanActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

class PeminjamanActionNotifier extends StateNotifier<PeminjamanActionState> {
  final AsetRepository _repository;
  final Ref _ref;

  PeminjamanActionNotifier(this._repository, this._ref)
      : super(const PeminjamanActionState());

  Future<bool> ajukanPeminjaman({
    required int asetId,
    required String tanggalPinjam,
    required String tanggalKembaliRencana,
    required String keperluan,
    String? catatan,
  }) async {
    state = const PeminjamanActionState(isLoading: true);
    try {
      final res = await _repository.simpanPeminjaman(
        asetId: asetId,
        tanggalPinjam: tanggalPinjam,
        tanggalKembaliRencana: tanggalKembaliRencana,
        keperluan: keperluan,
        catatan: catatan,
      );
      final kode = res['kode']?.toString() ?? 'Peminjaman';
      state = PeminjamanActionState(
        isLoading: false,
        successMessage: 'Permintaan peminjaman $kode berhasil diajukan.',
      );
      _ref.invalidate(daftarPeminjamanSayaProvider);
      _ref.invalidate(daftarApprovalPeminjamanProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = PeminjamanActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  Future<bool> batalkanPeminjaman(int id) async {
    state = const PeminjamanActionState(isLoading: true);
    try {
      await _repository.batalPeminjaman(id);
      state = const PeminjamanActionState(
        isLoading: false,
        successMessage: 'Permintaan peminjaman berhasil dibatalkan.',
      );
      _ref.invalidate(daftarPeminjamanSayaProvider);
      _ref.invalidate(daftarApprovalPeminjamanProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = PeminjamanActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  Future<bool> perpanjangPeminjaman({
    required int id,
    required String tanggalKembaliBaru,
    required String alasan,
  }) async {
    state = const PeminjamanActionState(isLoading: true);
    try {
      await _repository.perpanjangPeminjaman(
        id: id,
        tanggalKembaliBaru: tanggalKembaliBaru,
        alasan: alasan,
      );
      state = const PeminjamanActionState(
        isLoading: false,
        successMessage: 'Masa peminjaman berhasil diperpanjang.',
      );
      _ref.invalidate(daftarPeminjamanSayaProvider);
      _ref.invalidate(daftarPeminjamanAktifDipinjamProvider);
      _ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider);
      return true;
    } catch (e) {
      state = PeminjamanActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }

  Future<bool> otorisasi({
    required int id,
    required String aksi, // 'setujui', 'tolak', 'serah_terima'
    String? catatan,
  }) async {
    state = const PeminjamanActionState(isLoading: true);
    try {
      final res = await _repository.otorisasiPeminjaman(
        id: id,
        aksi: aksi,
        catatan: catatan,
      );
      String msg = 'Operasi berhasil dilakukan.';
      if (aksi == 'setujui') {
        msg = 'Peminjaman aset berhasil disetujui, siap diserahterimakan.';
      } else if (aksi == 'tolak') {
        msg = 'Permintaan peminjaman berhasil ditolak.';
      } else if (aksi == 'serah_terima') {
        msg = 'Serah terima fisik berhasil dikonfirmasi. Aset resmi berstatus DIPINJAM.';
      }

      state = PeminjamanActionState(
        isLoading: false,
        successMessage: res['pesan']?.toString() ?? msg,
      );
      _ref.invalidate(daftarApprovalPeminjamanProvider);
      _ref.invalidate(daftarPeminjamanSayaProvider);
      _ref.invalidate(daftarPeminjamanAktifDipinjamProvider);
      _ref.invalidate(daftarPeminjamanAktifDipinjamkanProvider);
      _ref.invalidate(registerAsetListProvider);
      _ref.invalidate(dashboardSummaryProvider);
      return true;
    } catch (e) {
      state = PeminjamanActionState(
        isLoading: false,
        errorMessage: e.toString().replaceAll('ApiException: ', ''),
      );
      return false;
    }
  }
}

final peminjamanActionProvider =
    StateNotifierProvider<PeminjamanActionNotifier, PeminjamanActionState>((ref) {
  final repository = ref.watch(asetRepositoryProvider);
  return PeminjamanActionNotifier(repository, ref);
});
