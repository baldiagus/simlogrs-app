import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/aset_tersedia_model.dart';
import '../../data/models/peminjaman_aset_model.dart';
import '../../data/repositories/aset_repository.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../master/presentation/providers/register_aset_provider.dart';
import 'aset_provider.dart';
/// Katalog aset yang tersedia untuk dipinjam, difilter dengan kata kunci pencarian.
final katalogAsetTersediaProvider =
    FutureProvider.autoDispose.family<List<AsetTersediaModel>, String>((ref, query) async {
  final repository = ref.watch(asetRepositoryProvider);
  return await repository.getKatalogTersedia(cari: query);
});

/// Katalog aset yang tersedia untuk dialihkan (tujuan pengalihan), difilter dengan kata kunci.
final katalogAsetPengalihanProvider =
    FutureProvider.autoDispose.family<List<AsetTersediaModel>, String>((ref, query) async {
  final repository = ref.watch(asetRepositoryProvider);
  return await repository.getKatalogTersedia(cari: query, tujuan: 'pengalihan');
});

/// Daftar peminjaman milik user sendiri (sebagai peminjam).
final daftarPeminjamanSayaProvider =
    FutureProvider.autoDispose<List<PeminjamanAsetModel>>((ref) async {
  final repository = ref.watch(asetRepositoryProvider);
  return await repository.getDaftarPeminjaman(perspektif: 'peminjam');
});

/// Daftar peminjaman milik user yang berstatus DIPINJAM (aset sedang dipegang user).
final daftarPeminjamanAktifDipinjamProvider =
    FutureProvider.autoDispose<List<PeminjamanAsetModel>>((ref) async {
  final repository = ref.watch(asetRepositoryProvider);
  final all = await repository.getDaftarPeminjaman(perspektif: 'peminjam');
  return all.where((item) => item.status == 'DIPINJAM').toList();
});

/// Daftar peminjaman aset milik penyedia yang berstatus DIPINJAM (aset sedang dipinjam pihak lain).
final daftarPeminjamanAktifDipinjamkanProvider =
    FutureProvider.autoDispose<List<PeminjamanAsetModel>>((ref) async {
  final repository = ref.watch(asetRepositoryProvider);
  final all = await repository.getDaftarPeminjaman(perspektif: 'penyedia');
  return all.where((item) => item.status == 'DIPINJAM').toList();
});

/// Daftar approval peminjaman; kosong bila user tidak punya izin/peran penyetuju.
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

/// State aksi peminjaman: status loading serta pesan error/sukses.
class PeminjamanActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  /// Membuat state aksi peminjaman; default idle tanpa pesan.
  const PeminjamanActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });
}

/// Notifier aksi peminjaman: ajukan, batal, perpanjang, dan otorisasi.
class PeminjamanActionNotifier extends StateNotifier<PeminjamanActionState> {
  final AsetRepository _repository;
  final Ref _ref;

  /// Membuat notifier dengan repository aset dan [Ref] untuk invalidasi provider terkait.
  PeminjamanActionNotifier(this._repository, this._ref)
      : super(const PeminjamanActionState());

  /// Mengajukan permintaan peminjaman aset; sukses menyegarkan daftar peminjaman, approval, dan dashboard.
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

  /// Membatalkan permintaan peminjaman [id]; sukses menyegarkan daftar peminjaman, approval, dan dashboard.
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

  /// Memperpanjang masa peminjaman [id] ke tanggal baru dengan [alasan]; sukses menyegarkan daftar peminjaman.
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

  /// Memproses otorisasi peminjaman [id] (setujui/tolak/serah terima) dan menyegarkan semua daftar terkait.
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

/// Provider [PeminjamanActionNotifier] untuk aksi peminjaman aset.
final peminjamanActionProvider =
    StateNotifierProvider<PeminjamanActionNotifier, PeminjamanActionState>((ref) {
  final repository = ref.watch(asetRepositoryProvider);
  return PeminjamanActionNotifier(repository, ref);
});
