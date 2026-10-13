import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simlog_mobile/core/offline/offline_queue.dart';

/// Pengujian antrean mutasi offline: urutan, penghapusan, dan persistensi.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('enqueue mempertahankan urutan dibuat dan ID unik', () async {
    final q = OfflineQueue(await SharedPreferences.getInstance());
    final a = await q.enqueue('lapor_cepat', {'x': 1});
    final b = await q.enqueue('hitung_fisik', {'y': 2});

    expect(q.count, 2);
    expect(q.daftar().map((e) => e.id).toList(), [a.id, b.id]);
    expect(a.id, isNot(b.id));
    expect(q.daftar().first.payload, {'x': 1});
  });

  test('remove hanya menghapus item bersangkutan', () async {
    final q = OfflineQueue(await SharedPreferences.getInstance());
    final a = await q.enqueue('lapor_cepat', {});
    final b = await q.enqueue('lapor_cepat', {});

    await q.remove(a.id);

    expect(q.daftar().map((e) => e.id).toList(), [b.id]);
  });

  test('data persisten antar instance dengan prefs sama', () async {
    final prefs = await SharedPreferences.getInstance();
    await OfflineQueue(prefs).enqueue('hitung_fisik', {
      'items': [1, 2]
    });

    final baru = OfflineQueue(prefs);

    expect(baru.count, 1);
    expect(baru.daftar().single.jenis, 'hitung_fisik');
    expect(baru.daftar().single.percobaan, 0);
  });

  test('tambahPercobaan menaikkan percobaan dan data rusak dianggap kosong', () async {
    final prefs = await SharedPreferences.getInstance();
    final q = OfflineQueue(prefs);
    final a = await q.enqueue('lapor_cepat', {});
    await q.tambahPercobaan(a.id);
    expect(q.daftar().single.percobaan, 1);

    await prefs.setString(OfflineQueue.kunci, '{bukan json list');
    expect(q.count, 0);
  });
}
