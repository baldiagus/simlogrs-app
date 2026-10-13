import '../network/api_response.dart';
import 'offline_queue.dart';

/// Pengirim satu jenis mutasi ke server; melempar [ApiException] bila gagal.
typedef OfflineHandler = Future<void> Function(Map<String, dynamic> payload);

/// Mengirim isi [OfflineQueue] ke server lewat handler per jenis mutasi.
class OfflineSyncService {
  final OfflineQueue queue;
  final Map<String, OfflineHandler> handlers;
  bool _sedangFlush = false;

  /// Membuat service dengan antrean [queue] dan [handlers] yang dipetakan per jenis.
  OfflineSyncService(this.queue, this.handlers);

  /// Memproses antrean berurutan (FIFO). Sukses dihapus; gagal jaringan menghentikan proses
  /// (percobaan bertambah, item tetap); gagal lain dibuang dan dikembalikan sebagai daftar gagal.
  Future<List<OfflineMutation>> flush() async {
    if (_sedangFlush) return [];
    _sedangFlush = true;
    final gagal = <OfflineMutation>[];
    try {
      for (final m in queue.daftar()) {
        final handler = handlers[m.jenis];
        if (handler == null) {
          await queue.remove(m.id);
          gagal.add(m);
          continue;
        }
        try {
          await handler(m.payload);
          await queue.remove(m.id);
        } on ApiException catch (e) {
          if (e.isNetworkError) {
            await queue.tambahPercobaan(m.id);
            break;
          }
          await queue.remove(m.id);
          gagal.add(m);
        } catch (_) {
          await queue.remove(m.id);
          gagal.add(m);
        }
      }
    } finally {
      _sedangFlush = false;
    }
    return gagal;
  }
}
