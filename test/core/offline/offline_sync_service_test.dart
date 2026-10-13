import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/core/offline/offline_queue.dart';
import 'package:simlog_mobile/core/offline/offline_sync_service.dart';

/// Pengujian flush antrean offline: sukses, gagal jaringan, gagal validasi, dan urutan FIFO.
void main() {
  late OfflineQueue queue;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    queue = OfflineQueue(await SharedPreferences.getInstance());
  });

  test('sukses menghapus item dengan urutan FIFO', () async {
    final urutan = <int>[];
    await queue.enqueue('lapor_cepat', {'n': 1});
    await queue.enqueue('lapor_cepat', {'n': 2});
    await queue.enqueue('lapor_cepat', {'n': 3});
    final svc = OfflineSyncService(queue, {
      'lapor_cepat': (p) async => urutan.add(p['n'] as int),
    });

    final gagal = await svc.flush();

    expect(urutan, [1, 2, 3]);
    expect(gagal, isEmpty);
    expect(queue.count, 0);
  });

  test('error jaringan menghentikan flush, item tetap dan percobaan bertambah', () async {
    final dipanggil = <int>[];
    await queue.enqueue('lapor_cepat', {'n': 1});
    await queue.enqueue('lapor_cepat', {'n': 2});
    final svc = OfflineSyncService(queue, {
      'lapor_cepat': (p) async {
        dipanggil.add(p['n'] as int);
        throw ApiException(message: 'offline', isNetworkError: true);
      },
    });

    final gagal = await svc.flush();

    expect(dipanggil, [1]);
    expect(gagal, isEmpty);
    expect(queue.count, 2);
    expect(queue.daftar().first.percobaan, 1);
    expect(queue.daftar().last.percobaan, 0);
  });

  test('error 422 membuang item, dilaporkan gagal, item berikutnya tetap diproses', () async {
    final ok = <int>[];
    await queue.enqueue('hitung_fisik', {'n': 1});
    await queue.enqueue('hitung_fisik', {'n': 2});
    final svc = OfflineSyncService(queue, {
      'hitung_fisik': (p) async {
        if (p['n'] == 1) throw ApiException(message: 'invalid', statusCode: 422);
        ok.add(p['n'] as int);
      },
    });

    final gagal = await svc.flush();

    expect(gagal.map((e) => e.payload['n']).toList(), [1]);
    expect(ok, [2]);
    expect(queue.count, 0);
  });

  test('jenis tanpa handler dibuang dan dilaporkan gagal', () async {
    await queue.enqueue('tak_dikenal', {});
    final svc = OfflineSyncService(queue, {});

    final gagal = await svc.flush();

    expect(gagal.single.jenis, 'tak_dikenal');
    expect(queue.count, 0);
  });
}
