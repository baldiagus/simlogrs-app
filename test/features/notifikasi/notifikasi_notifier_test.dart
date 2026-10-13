import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/models/pagination_meta.dart';
import 'package:simlog_mobile/features/notifikasi/data/models/notifikasi_model.dart';
import 'package:simlog_mobile/features/notifikasi/data/repositories/notifikasi_repository.dart';
import 'package:simlog_mobile/features/notifikasi/presentation/providers/notifikasi_provider.dart';

/// Repository notifikasi tiruan: halaman berisi [perHalaman] item, total [total] item.
class FakeNotifikasiRepository extends Fake implements NotifikasiRepository {
  final int total;
  final int perHalaman;
  int belumDibaca;
  bool gagalTandai = false;
  final List<int> dibacaIds = [];
  int bacaSemuaDipanggil = 0;

  /// Membuat [FakeNotifikasiRepository].
  FakeNotifikasiRepository({this.total = 5, this.perHalaman = 3, this.belumDibaca = 5});

  /// Mengembalikan halaman tiruan; semua item awalnya belum dibaca.
  @override
  Future<NotifikasiPage> getDaftar({int page = 1, bool hanyaBelumDibaca = false}) async {
    final awal = (page - 1) * perHalaman;
    final akhir = (awal + perHalaman).clamp(0, total);
    final items = [for (var i = awal; i < akhir; i++) _item(i + 1)];
    return NotifikasiPage(
      halaman: PagedResponse(
        items: items,
        meta: PaginationMeta(
          total: total,
          perHalaman: perHalaman,
          halamanIni: page,
          totalHalaman: (total / perHalaman).ceil(),
        ),
      ),
      belumDibaca: belumDibaca,
    );
  }

  /// Mencatat ID dibaca dan mengembalikan sisa belum dibaca, atau gagal bila [gagalTandai].
  @override
  Future<int> tandaiDibaca(int id) async {
    if (gagalTandai) throw Exception('gagal');
    dibacaIds.add(id);
    belumDibaca -= 1;
    return belumDibaca;
  }

  /// Mencatat pemanggilan bacaSemua.
  @override
  Future<void> bacaSemua() async {
    bacaSemuaDipanggil++;
    belumDibaca = 0;
  }

  /// Membangun notifikasi tiruan belum dibaca dengan [id].
  NotifikasiModel _item(int id) => NotifikasiModel(
        id: id,
        judul: 'Judul $id',
        pesan: 'Pesan $id',
        tipe: 'UMUM',
        dibuatPada: DateTime.utc(2026, 10, 13),
      );
}

/// Membuat notifier + container dengan repository [repo].
(NotifikasiListNotifier, ProviderContainer) buat(FakeNotifikasiRepository repo) {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return (NotifikasiListNotifier(repo, container.read(belumDibacaProvider.notifier)), container);
}

/// Pengujian [NotifikasiListNotifier].
void main() {
  test('loadInitial mengisi item dan belumDibaca', () async {
    final (n, c) = buat(FakeNotifikasiRepository());
    await n.loadInitial();
    expect(n.state.items, hasLength(3));
    expect(n.state.hasMore, isTrue);
    expect(c.read(belumDibacaProvider), 5);
  });

  test('loadMore menambah item dan berhenti di halaman terakhir', () async {
    final (n, _) = buat(FakeNotifikasiRepository());
    await n.loadInitial();
    await n.loadMore();
    expect(n.state.items.map((e) => e.id), [1, 2, 3, 4, 5]);
    expect(n.state.page, 2);
    expect(n.state.hasMore, isFalse);
    await n.loadMore();
    expect(n.state.items, hasLength(5));
  });

  test('tandaiDibaca optimistis menurunkan belumDibaca dan menandai item', () async {
    final repo = FakeNotifikasiRepository();
    final (n, c) = buat(repo);
    await n.loadInitial();
    final future = n.tandaiDibaca(2);
    expect(n.state.items[1].dibaca, isTrue);
    expect(c.read(belumDibacaProvider), 4);
    await future;
    expect(repo.dibacaIds, [2]);
    expect(c.read(belumDibacaProvider), 4);
    await n.tandaiDibaca(2);
    expect(repo.dibacaIds, [2], reason: 'item yang sudah dibaca tidak memanggil server lagi');
  });

  test('tandaiDibaca dikembalikan ke semula bila server gagal', () async {
    final repo = FakeNotifikasiRepository()..gagalTandai = true;
    final (n, c) = buat(repo);
    await n.loadInitial();
    await n.tandaiDibaca(1);
    expect(n.state.items.first.dibaca, isFalse);
    expect(c.read(belumDibacaProvider), 5);
  });

  test('bacaSemua menandai semua item dan menolkan belumDibaca', () async {
    final repo = FakeNotifikasiRepository();
    final (n, c) = buat(repo);
    await n.loadInitial();
    await n.bacaSemua();
    expect(n.state.items.every((e) => e.dibaca), isTrue);
    expect(c.read(belumDibacaProvider), 0);
    expect(repo.bacaSemuaDipanggil, 1);
  });
}
