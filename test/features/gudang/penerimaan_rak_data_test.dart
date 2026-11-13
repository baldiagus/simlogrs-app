import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/core/network/dio_client.dart';
import 'package:simlog_mobile/core/storage/secure_storage_service.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/gudang/data/models/po_inbound_model.dart';
import 'package:simlog_mobile/features/gudang/data/models/rak_model.dart';
import 'package:simlog_mobile/features/gudang/data/repositories/gudang_repository.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/gudang_provider.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/inbound_provider.dart';

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(UserModel user) : super(AuthState.authenticated(user));
  void switchUser(UserModel user) => state = AuthState.authenticated(user);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

UserModel _user(int id, {int? warehouse = 10, bool admin = false}) => UserModel(
  id: id, name: 'Penerima uji', email: 'penerima$id@example.test',
  roles: [admin ? 'admin_logistik' : 'petugas_gudang'],
  permissions: const ['create_gudang_stok::penerimaan::po'],
  gudang: warehouse == null ? null : GudangModel(id: warehouse, nama: 'Gudang $warehouse'),
);

RakModel _rack(int id, int warehouse, {String status = 'AKTIF'}) => RakModel(
  id: id, kode: 'RAK-$id', nama: 'Rak $id', status: status,
  gudangId: warehouse, namaGudang: 'Gudang $warehouse', totalBarang: 0, totalAset: 0,
);

class _Repository extends Fake implements GudangRepository {
  final calls = <int?>[];
  Future<List<RakModel>> Function(int?) racks = (_) async => [];
  Map<String, dynamic>? submitted;
  ApiException? submitError;

  @override
  Future<List<RakModel>> getDaftarRak({String? cari, int? gudangId}) {
    calls.add(gudangId);
    return racks(gudangId);
  }

  @override
  Future<Map<String, dynamic>> submitPenerimaanPo({
    required int poId, required int gudangId, required String nomorSuratJalan,
    String? catatan, required List<Map<String, dynamic>> items,
  }) async {
    submitted = {'gudang_id': gudangId, 'items': items, 'catatan': catatan};
    if (submitError != null) throw submitError!;
    return {'kode_rcv': 'RCV-UJI'};
  }
}

ProviderContainer _container(_Repository repo, _Auth auth) {
  final container = ProviderContainer(overrides: [
    gudangRepositoryProvider.overrideWithValue(repo),
    authStateProvider.overrideWith((_) => auth),
  ]);
  addTearDown(container.dispose);
  return container;
}

class _Storage extends Fake implements SecureStorageService {
  @override
  Future<String?> getToken() async => 'dummy-token';
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.body);
  final Object? body;
  RequestOptions? request;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? stream, Future<void>? cancel) async {
    request = options;
    return ResponseBody.fromString(jsonEncode(body), 200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }
  @override
  void close({bool force = false}) {}
}

GudangRepository _http(_Adapter adapter) => GudangRepository(DioClient(
  storageService: _Storage(), customDio: Dio()..httpClientAdapter = adapter,
));

const _item = PoInboundItemModel(id: 1, barangId: 8, kodeBarang: 'BRG-UJI',
  namaBarang: 'Barang uji', satuan: 'Pcs', jumlahDipesan: 10,
  jumlahSudahDiterima: 0, sisaKebutuhan: 10, hargaSatuan: 1000);

void main() {
  test('rack request scopes warehouse and malformed responses are errors, not empty lists', () async {
    final adapter = _Adapter({'sukses': true, 'data': [
      {'id': 11, 'kode': 'RAK-11', 'gudang_id': 10, 'status': 'AKTIF'},
    ]});
    final result = await _http(adapter).getDaftarRak(gudangId: 10);
    expect(adapter.request!.queryParameters, {'gudang_id': 10});
    expect(result.single.gudangId, 10);
    for (final data in [null, {'items': []}, [{'id': 'invalid'}]]) {
      await expectLater(_http(_Adapter({'sukses': true, 'data': data})).getDaftarRak(gudangId: 10),
        throwsA(isA<ApiException>()));
    }
    expect(await _http(_Adapter({'sukses': true, 'data': []})).getDaftarRak(gudangId: 10), isEmpty);
  });

  test('HTTP receipt sends explicit warehouse and selected rack', () async {
    final adapter = _Adapter({'sukses': true, 'data': {'kode_rcv': 'RCV-UJI'}});
    await _http(adapter).submitPenerimaanPo(poId: 2, gudangId: 10,
      nomorSuratJalan: 'SJ-UJI', items: [{'barang_id': 8, 'lokasi_gudang_id': 11}]);
    expect(adapter.request!.path, '/gudang/penerimaan-po');
    expect(adapter.request!.data['gudang_id'], 10);
    expect(adapter.request!.data['items'].single['lokasi_gudang_id'], 11);
  });

  test('assigned receiver only sees active racks of the selected assigned warehouse', () async {
    final repo = _Repository()..racks = (_) async => [_rack(11, 10), _rack(12, 20), _rack(13, 10, status: 'NONAKTIF')];
    final container = _container(repo, _Auth(_user(1)));
    final racks = await container.read(rakPenerimaanProvider(10).future);
    expect(racks.map((rack) => rack.id), [11]);
    expect(repo.calls, [10]);
    await expectLater(container.read(rakPenerimaanProvider(20).future), throwsA(isA<ApiException>()));
    expect(repo.calls, [10]);
  });

  test('global admin with assignment cannot silently select another warehouse', () async {
    final repo = _Repository();
    final container = _container(repo, _Auth(_user(1, admin: true)));
    await expectLater(container.read(rakPenerimaanProvider(20).future), throwsA(isA<ApiException>()));
    expect(repo.calls, isEmpty);
  });

  test('admin without assignment can query an explicit warehouse, other unassigned accounts cannot', () async {
    final repo = _Repository()..racks = (id) async => [_rack(21, id!)];
    final auth = _Auth(_user(1, warehouse: null, admin: true));
    final container = _container(repo, auth);
    expect((await container.read(rakPenerimaanProvider(20).future)).single.id, 21);
    auth.switchUser(_user(2, warehouse: null));
    await expectLater(container.read(rakPenerimaanProvider(20).future), throwsA(isA<ApiException>()));
    expect(repo.calls, [20]);
  });

  test('a response from the previous account cannot overwrite rack state after account change', () async {
    final oldResponse = Completer<List<RakModel>>();
    final repo = _Repository();
    repo.racks = (_) => repo.calls.length == 1 ? oldResponse.future : Future.value([_rack(22, 10)]);
    final auth = _Auth(_user(1));
    final container = _container(repo, auth);
    final provider = rakPenerimaanProvider(10);
    container.listen(provider, (_, __) {});
    auth.switchUser(_user(2));
    expect((await container.read(provider.future)).single.id, 22);
    oldResponse.complete([_rack(11, 10)]);
    await container.pump();
    expect(container.read(provider).requireValue.single.id, 22);
  });

  test('receipt action preserves explicit target, filters zero quantity, and exposes 422 for draft recovery', () async {
    final repo = _Repository()..submitError = ApiException(message: 'Rak sudah tidak aktif', statusCode: 422);
    final container = _container(repo, _Auth(_user(1)));
    final draft = InboundItemDraft(poItem: _item, jumlahDiterima: 2, nomorBatch: 'BATCH-UJI', lokasiGudangId: 11);
    final skipped = InboundItemDraft(poItem: _item, jumlahDiterima: 0, nomorBatch: 'LEWATI');
    final ok = await container.read(inboundActionProvider.notifier).submitPenerimaan(
      poId: 2, gudangId: 10, nomorSuratJalan: 'SJ-UJI', items: [draft, skipped]);
    expect(ok, isFalse);
    expect(repo.submitted!['gudang_id'], 10);
    expect(repo.submitted!['items'], hasLength(1));
    expect(container.read(inboundActionProvider).statusCode, 422);
    expect(container.read(inboundActionProvider).errorMessage, contains('Rak sudah tidak aktif'));
    expect(draft.nomorBatch, 'BATCH-UJI');
    expect(draft.jumlahDiterima, 2);
    expect(draft.lokasiGudangId, 11);
  });
}
