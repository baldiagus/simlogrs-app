import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/models/pagination_meta.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/master_barang_model.dart';
import 'package:simlog_mobile/features/pengadaan/data/repositories/pengadaan_repository.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/providers/pengadaan_provider.dart';

class _Request {
  _Request(this.cari, this.tipe, this.page, this.perHalaman);

  final String? cari;
  final String? tipe;
  final int page;
  final int perHalaman;
  final result = Completer<PagedResponse<MasterBarangModel>>();
}

class _Repository extends Fake implements PengadaanRepository {
  final requests = <_Request>[];

  @override
  Future<PagedResponse<MasterBarangModel>> getKatalogBarang({
    String? cari,
    String? tipe,
    int page = 1,
    int perHalaman = 50,
  }) {
    final request = _Request(cari, tipe, page, perHalaman);
    requests.add(request);
    return request.result.future;
  }
}

MasterBarangModel _barang(int id) => MasterBarangModel(
      id: id,
      kode: 'BRG-$id',
      nama: 'Barang $id',
      kategori: 'Umum',
      satuan: 'Pcs',
      merek: '-',
      hargaEstimasi: 1000,
    );

PagedResponse<MasterBarangModel> _page(List<int> ids, int page, {int pages = 2}) =>
    PagedResponse(
      items: ids.map(_barang).toList(),
      meta: PaginationMeta(
        total: pages * 50,
        perHalaman: 50,
        halamanIni: page,
        totalHalaman: pages,
      ),
    );

ProviderContainer _watch(_Repository repository, KatalogBarangParams params) {
  final container = ProviderContainer(overrides: [
    pengadaanRepositoryProvider.overrideWithValue(repository),
  ]);
  addTearDown(container.dispose);
  container.listen(katalogBarangProvider(params), (_, __) {});
  return container;
}

void main() {
  testWidgets('initial load forwards query/type and appends unique IDs in page order', (tester) async {
    final repository = _Repository();
    const params = KatalogBarangParams(query: 'pom', tipe: 'ASET');
    final container = _watch(repository, params);
    final provider = katalogBarangProvider(params);
    final notifier = container.read(provider.notifier);

    expect(container.read(provider).isLoading, isTrue);
    expect(repository.requests, hasLength(1));
    expect(repository.requests.single.cari, 'pom');
    expect(repository.requests.single.tipe, 'ASET');
    expect(repository.requests.single.page, 1);
    expect(repository.requests.single.perHalaman, 50);
    repository.requests.single.result.complete(_page([1, 2], 1));
    await tester.pump();

    expect(container.read(provider).items.map((item) => item.id), [1, 2]);
    expect(container.read(provider).page, 1);
    expect(container.read(provider).hasMore, isTrue);
    expect(container.read(provider).isLoading, isFalse);
    final next = notifier.loadMore();
    expect(container.read(provider).isLoadingMore, isTrue);
    expect(repository.requests.last.page, 2);
    repository.requests.last.result.complete(_page([2, 3], 2));
    await next;

    final state = container.read(provider);
    expect(state.items.map((item) => item.id), [1, 2, 3]);
    expect(state.page, 2);
    expect(state.hasMore, isFalse);
    expect(state.isLoadingMore, isFalse);
    await notifier.loadMore();
    expect(repository.requests, hasLength(2));
  });

  testWidgets('concurrent scroll requests cannot fetch the same next page twice', (tester) async {
    final repository = _Repository();
    const params = KatalogBarangParams(query: '');
    final container = _watch(repository, params);
    final notifier = container.read(katalogBarangProvider(params).notifier);

    await notifier.loadMore();
    expect(repository.requests, hasLength(1));
    repository.requests.single.result.complete(_page([1], 1));
    await tester.pump();

    final first = notifier.loadMore();
    final second = notifier.loadMore();
    expect(repository.requests.map((request) => request.page), [1, 2]);
    repository.requests.last.result.complete(_page([2], 2));
    await Future.wait([first, second]);
    expect(container.read(katalogBarangProvider(params)).items.map((item) => item.id), [1, 2]);
  });

  testWidgets('failed next page preserves successful items/page and retries that page', (tester) async {
    final repository = _Repository();
    const params = KatalogBarangParams(query: '');
    final container = _watch(repository, params);
    final provider = katalogBarangProvider(params);
    final notifier = container.read(provider.notifier);
    repository.requests.single.result.complete(_page([1, 2], 1));
    await tester.pump();

    final failed = notifier.loadMore();
    repository.requests.last.result.completeError(ApiException(message: 'Halaman gagal'));
    await failed;
    final state = container.read(provider);
    expect(state.items.map((item) => item.id), [1, 2]);
    expect(state.page, 1);
    expect(state.hasMore, isTrue);
    expect(state.errorMessage, contains('Halaman gagal'));
    expect(state.isLoadingMore, isFalse);

    final retry = notifier.loadMore();
    expect(repository.requests.map((request) => request.page), [1, 2, 2]);
    repository.requests.last.result.complete(_page([3], 2));
    await retry;
    expect(container.read(provider).items.map((item) => item.id), [1, 2, 3]);
    expect(container.read(provider).page, 2);
    expect(container.read(provider).errorMessage, isNull);
  });

  testWidgets('failed initial request is retryable through refresh', (tester) async {
    final repository = _Repository();
    const params = KatalogBarangParams(query: '');
    final container = _watch(repository, params);
    final provider = katalogBarangProvider(params);
    repository.requests.single.result.completeError(ApiException(message: 'Katalog gagal'));
    await tester.pump();
    expect(container.read(provider).items, isEmpty);
    expect(container.read(provider).isLoading, isFalse);
    expect(container.read(provider).errorMessage, contains('Katalog gagal'));

    final retry = container.read(provider.notifier).refresh();
    expect(container.read(provider).isLoading, isTrue);
    expect(repository.requests.last.page, 1);
    repository.requests.last.result.complete(_page([7], 1, pages: 1));
    await retry;
    expect(container.read(provider).items.single.id, 7);
    expect(container.read(provider).errorMessage, isNull);
  });

  testWidgets('refresh clears accumulated data and ignores an older pending next page', (tester) async {
    final repository = _Repository();
    const params = KatalogBarangParams(query: '');
    final container = _watch(repository, params);
    final provider = katalogBarangProvider(params);
    final notifier = container.read(provider.notifier);
    repository.requests.single.result.complete(_page([1], 1, pages: 3));
    await tester.pump();
    final second = notifier.loadMore();
    repository.requests.last.result.complete(_page([2], 2, pages: 3));
    await second;
    expect(container.read(provider).page, 2);
    expect(container.read(provider).items.map((item) => item.id), [1, 2]);
    final oldNext = notifier.loadMore();
    final oldRequest = repository.requests.last;

    final refresh = notifier.refresh();
    expect(container.read(provider).items, isEmpty);
    expect(container.read(provider).page, 1);
    expect(container.read(provider).isLoading, isTrue);
    expect(repository.requests.last.page, 1);
    repository.requests.last.result.complete(_page([9], 1, pages: 1));
    await refresh;
    oldRequest.result.complete(_page([3], 3, pages: 3));
    await oldNext;

    expect(container.read(provider).items.map((item) => item.id), [9]);
    expect(container.read(provider).page, 1);
    expect(container.read(provider).hasMore, isFalse);
    expect(container.read(provider).isLoadingMore, isFalse);
  });

  testWidgets('the same query has isolated catalogue state for each type', (tester) async {
    final repository = _Repository();
    const allParams = KatalogBarangParams(query: 'filter');
    final container = _watch(repository, allParams);
    final allProvider = katalogBarangProvider(allParams);
    final sparepartProvider = katalogBarangProvider(
      const KatalogBarangParams(query: 'filter', tipe: 'SPAREPART'),
    );
    container.listen(sparepartProvider, (_, __) {});
    expect(repository.requests, hasLength(2));
    repository.requests[1].result.complete(_page([9], 1, pages: 1));
    await tester.pump();
    expect(container.read(allProvider).isLoading, isTrue);
    expect(container.read(sparepartProvider).items.single.id, 9);

    repository.requests[0].result.complete(_page([1], 1));
    await tester.pump();
    expect(container.read(allProvider).items.single.id, 1);
    expect(container.read(allProvider).hasMore, isTrue);
    expect(container.read(sparepartProvider).items.single.id, 9);
    expect(container.read(sparepartProvider).hasMore, isFalse);
  });

  testWidgets('an old query completing later cannot overwrite the new query provider', (tester) async {
    final repository = _Repository();
    final container = ProviderContainer(overrides: [
      pengadaanRepositoryProvider.overrideWithValue(repository),
    ]);
    addTearDown(container.dispose);
    final oldProvider = katalogBarangProvider(const KatalogBarangParams(query: 'p'));
    final oldSubscription = container.listen(oldProvider, (_, __) {});
    final oldRequest = repository.requests.single;
    final newProvider = katalogBarangProvider(const KatalogBarangParams(query: 'pom', tipe: 'ASET'));
    container.listen(newProvider, (_, __) {});
    oldSubscription.close();
    await tester.pump(const Duration(milliseconds: 1));

    repository.requests.last.result.complete(_page([99], 1, pages: 1));
    await tester.pump();
    oldRequest.result.complete(_page([1], 1));
    await tester.pump();

    expect(container.read(newProvider).items.map((item) => item.id), [99]);
    expect(container.read(newProvider).hasMore, isFalse);
    expect(repository.requests.map((request) => request.cari), ['p', 'pom']);
  });

  for (final fails in [false, true]) {
    testWidgets('disposed notifier ignores delayed ${fails ? 'failure' : 'success'}', (tester) async {
      final repository = _Repository();
      final notifier = KatalogBarangNotifier(repository, const KatalogBarangParams(query: 'lama'));
      final snapshots = <PagedListState<MasterBarangModel>>[];
      notifier.addListener(snapshots.add);
      notifier.dispose();
      final beforeCompletion = snapshots.length;

      if (fails) {
        repository.requests.single.result.completeError(ApiException(message: 'Terlambat'));
      } else {
        repository.requests.single.result.complete(_page([1], 1));
      }
      await tester.pump();

      expect(snapshots, hasLength(beforeCompletion));
      expect(tester.takeException(), isNull);
    });
  }
}
