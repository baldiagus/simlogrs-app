import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/models/pagination_meta.dart';
import 'package:simlog_mobile/features/audit/data/models/audit_models.dart';
import 'package:simlog_mobile/features/audit/data/repositories/audit_repository.dart';
import 'package:simlog_mobile/features/audit/presentation/providers/audit_provider.dart';

/// Repository audit tiruan untuk menguji skenario pemuatan berhalaman dan filter [AuditTrailNotifier].
class FakeAuditRepository extends Fake implements AuditRepository {
  /// Rekaman panggilan untuk memeriksa parameter yang dikirim notifier.
  final List<Map<String, dynamic>> calls = [];

  /// Fungsi pengembali data per request.
  final PagedResponse<AuditTrailItemModel> Function(int page, String? aksi, String? search)? responder;

  /// Membuat instance [FakeAuditRepository].
  FakeAuditRepository([this.responder]);

  /// Mengembalikan data jejak audit tiruan sesuai halaman dan filter.
  @override
  Future<PagedResponse<AuditTrailItemModel>> getAuditTrail({
    String? aksi,
    String? entitas,
    String? search,
    int page = 1,
  }) async {
    calls.add({
      'page': page,
      'aksi': aksi,
      'entitas': entitas,
      'search': search,
    });
    if (responder != null) {
      return responder!(page, aksi, search);
    }
    return PagedResponse.empty();
  }
}

/// Membangun model item jejak audit tiruan untuk kebutuhan pengujian.
AuditTrailItemModel mockItem({required int id, String aksi = 'TAMBAH', String pengguna = 'User'}) {
  return AuditTrailItemModel(
    id: id,
    penggunaNama: pengguna,
    penggunaNip: '19800101',
    peran: 'Auditor',
    aksi: aksi,
    referensiJenis: 'Barang',
    referensiId: id * 10,
    ipAddress: '127.0.0.1',
    device: 'Mobile',
    waktu: 'Baru saja',
    timestamp: '2026-10-13T09:00:00Z',
    hasDataSebelum: false,
    hasDataSesudah: true,
  );
}

/// Rangkaian pengujian unit untuk [AuditTrailNotifier].
void main() {
  group('AuditTrailNotifier', () {
    test('loadInitial memuat halaman 1 dan mengatur state dengan benar', () async {
      final fakeRepo = FakeAuditRepository((page, aksi, search) {
        return PagedResponse(
          items: [mockItem(id: 1), mockItem(id: 2)],
          meta: const PaginationMeta(
            total: 50,
            perHalaman: 2,
            halamanIni: 1,
            totalHalaman: 25,
          ),
        );
      });

      final notifier = AuditTrailNotifier(fakeRepo);
      expect(notifier.state.isLoading, isTrue);

      await notifier.loadInitial();

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.items.length, 2);
      expect(notifier.state.page, 1);
      expect(notifier.state.hasMore, isTrue);
      expect(fakeRepo.calls.single['page'], 1);
    });

    test('loadMore menambah item ke daftar dan menaikkan nomor halaman', () async {
      final fakeRepo = FakeAuditRepository((page, aksi, search) {
        if (page == 1) {
          return PagedResponse(
            items: [mockItem(id: 1), mockItem(id: 2)],
            meta: const PaginationMeta(
              total: 4,
              perHalaman: 2,
              halamanIni: 1,
              totalHalaman: 2,
            ),
          );
        }
        return PagedResponse(
          items: [mockItem(id: 3), mockItem(id: 4)],
          meta: const PaginationMeta(
            total: 4,
            perHalaman: 2,
            halamanIni: 2,
            totalHalaman: 2,
          ),
        );
      });

      final notifier = AuditTrailNotifier(fakeRepo);
      await notifier.loadInitial();

      expect(notifier.state.items.length, 2);
      expect(notifier.state.page, 1);
      expect(notifier.state.hasMore, isTrue);

      await notifier.loadMore();

      expect(notifier.state.items.length, 4);
      expect(notifier.state.items.map((e) => e.id), [1, 2, 3, 4]);
      expect(notifier.state.page, 2);
      expect(notifier.state.hasMore, isFalse);
      expect(notifier.state.isLoadingMore, isFalse);
    });

    test('hasMore bernilai false saat halaman terakhir dan loadMore lanjutan diabaikan', () async {
      final fakeRepo = FakeAuditRepository((page, aksi, search) {
        return PagedResponse(
          items: [mockItem(id: 10)],
          meta: const PaginationMeta(
            total: 1,
            perHalaman: 20,
            halamanIni: 1,
            totalHalaman: 1,
          ),
        );
      });

      final notifier = AuditTrailNotifier(fakeRepo);
      await notifier.loadInitial();

      expect(notifier.state.hasMore, isFalse);
      expect(notifier.state.page, 1);
      final initialCallCount = fakeRepo.calls.length;

      // Panggilan lanjutan tidak boleh memicu request lagi.
      await notifier.loadMore();
      expect(fakeRepo.calls.length, initialCallCount);
      expect(notifier.state.items.length, 1);
    });

    test('filter dan search mereset state kembali ke halaman 1', () async {
      final fakeRepo = FakeAuditRepository((page, aksi, search) {
        if (aksi == 'UBAH') {
          return PagedResponse(
            items: [mockItem(id: 99, aksi: 'UBAH')],
            meta: const PaginationMeta(
              total: 1,
              perHalaman: 10,
              halamanIni: 1,
              totalHalaman: 1,
            ),
          );
        }
        return PagedResponse(
          items: [mockItem(id: page, aksi: 'TAMBAH')],
          meta: PaginationMeta(
            total: 20,
            perHalaman: 1,
            halamanIni: page,
            totalHalaman: 20,
          ),
        );
      });

      final notifier = AuditTrailNotifier(fakeRepo);
      await notifier.loadInitial();
      await notifier.loadMore();

      expect(notifier.state.page, 2);
      expect(notifier.state.items.length, 2);

      // Terapkan filter aksi baru.
      await notifier.setFilter(aksi: 'UBAH', search: 'obat');

      expect(notifier.state.page, 1);
      expect(notifier.state.items.length, 1);
      expect(notifier.state.items.first.aksi, 'UBAH');
      expect(notifier.aksi, 'UBAH');
      expect(notifier.search, 'obat');
      expect(fakeRepo.calls.last['aksi'], 'UBAH');
      expect(fakeRepo.calls.last['search'], 'obat');
      expect(fakeRepo.calls.last['page'], 1);
    });

    test('refresh memuat ulang data dari halaman 1 tanpa menghilangkan data sebelum selesai', () async {
      int fetchCount = 0;
      final fakeRepo = FakeAuditRepository((page, aksi, search) {
        fetchCount++;
        return PagedResponse(
          items: [mockItem(id: fetchCount)],
          meta: const PaginationMeta(
            total: 10,
            perHalaman: 1,
            halamanIni: 1,
            totalHalaman: 10,
          ),
        );
      });

      final notifier = AuditTrailNotifier(fakeRepo);
      await notifier.loadInitial();
      expect(notifier.state.items.single.id, 1);

      await notifier.refresh();
      expect(notifier.state.items.single.id, 2);
      expect(notifier.state.page, 1);
    });
  });
}
