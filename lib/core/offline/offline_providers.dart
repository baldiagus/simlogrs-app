import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/gudang/data/repositories/persediaan_repository.dart';
import '../../features/maintenance/presentation/providers/maintenance_provider.dart';
import 'offline_queue.dart';
import 'offline_sync_service.dart';

/// Provider SharedPreferences (async); dapat di-override pada test.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// Provider antrean mutasi offline di atas SharedPreferences.
final offlineQueueProvider = FutureProvider<OfflineQueue>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return OfflineQueue(prefs);
});

/// Provider service sinkron dengan handler lapor_cepat dan hitung_fisik ke repository terkait.
final offlineSyncServiceProvider = FutureProvider<OfflineSyncService>((ref) async {
  final queue = await ref.watch(offlineQueueProvider.future);
  final maintenance = ref.watch(maintenanceRepositoryProvider);
  final persediaan = ref.watch(persediaanRepositoryProvider);
  return OfflineSyncService(queue, {
    OfflineMutation.jenisLaporCepat: (p) async {
      await maintenance.submitLaporCepat(
        asetId: p['aset_id'] as int?,
        kodeAset: p['kode_aset'] as String?,
        deskripsiMasalah: p['deskripsi'] as String,
        prioritas: p['prioritas'] as String,
      );
    },
    OfflineMutation.jenisHitungFisik: (p) async {
      await persediaan.simpanHitungFisik(
        opnameId: p['opname_id'] as int,
        items: (p['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        finalisasi: p['finalisasi'] == true,
      );
    },
  });
});

/// Notifier jumlah mutasi yang menunggu dikirim; state-nya dipakai UI untuk banner reaktif.
class OfflineQueueNotifier extends StateNotifier<int> {
  final Ref _ref;

  /// Membuat notifier dan langsung memuat jumlah antrean tersimpan.
  OfflineQueueNotifier(this._ref) : super(0) {
    muat();
  }

  /// Memuat ulang jumlah antrean dari penyimpanan ke state.
  Future<void> muat() async {
    final queue = await _ref.read(offlineQueueProvider.future);
    if (mounted) state = queue.count;
  }

  /// Menambah mutasi [jenis] dengan [payload] ke antrean lalu memperbarui jumlah.
  Future<void> enqueue(String jenis, Map<String, dynamic> payload) async {
    final queue = await _ref.read(offlineQueueProvider.future);
    await queue.enqueue(jenis, payload);
    if (mounted) state = queue.count;
  }

  /// Mengirim antrean ke server; mengembalikan mutasi yang ditolak server (dibuang dari antrean).
  Future<List<OfflineMutation>> flush() async {
    final service = await _ref.read(offlineSyncServiceProvider.future);
    final gagal = await service.flush();
    if (mounted) state = service.queue.count;
    return gagal;
  }
}

/// Provider jumlah antrean offline beserta aksi enqueue dan flush.
final offlineQueueCountProvider =
    StateNotifierProvider<OfflineQueueNotifier, int>((ref) => OfflineQueueNotifier(ref));
