import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/core/network/api_response.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/gudang/data/models/po_inbound_model.dart';
import 'package:simlog_mobile/features/gudang/data/models/rak_model.dart';
import 'package:simlog_mobile/features/gudang/data/repositories/gudang_repository.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/gudang_provider.dart';
import 'package:simlog_mobile/features/gudang/presentation/screens/form_penerimaan_po_screen.dart';
import 'package:simlog_mobile/features/gudang/presentation/widgets/inbound_item_draft_tile.dart';
import 'package:simlog_mobile/features/master/presentation/providers/master_barang_provider.dart';
import 'package:simlog_mobile/shared/widgets/app_quantity_stepper.dart';
import 'package:simlog_mobile/shared/widgets/custom_button.dart';

const _warehouses = [
  GudangModel(id: 1, nama: 'Gudang Medis'),
  GudangModel(id: 2, nama: 'Gudang Umum'),
];
const _po = PoInboundHeaderModel(
  id: 1, kodePo: 'PO-SCOPE', pemasok: 'Vendor Uji', tanggalPo: '2026-11-13',
  status: 'DIKIRIM_VENDOR', totalItem: 1,
  items: [PoInboundItemModel(
    id: 1, barangId: 1, kodeBarang: 'BRG-1', namaBarang: 'Sarung Tangan',
    satuan: 'Box', jumlahDipesan: 5, jumlahSudahDiterima: 0,
    sisaKebutuhan: 5, hargaSatuan: 100,
  )],
);
RakModel _rack(int id, int warehouse, {String status = 'AKTIF'}) => RakModel(
  id: id, kode: 'RAK-$id', nama: 'Rak $id', status: status,
  gudangId: warehouse, namaGudang: 'Gudang $warehouse', totalBarang: 0, totalAset: 0,
);
UserModel _user({int id = 1, String role = 'petugas_gudang', int? warehouse = 1,
  List<String> permissions = const []}) => UserModel(
  id: id, name: 'Penerima', email: 'uji@example.test', roles: [role],
  permissions: permissions,
  gudang: warehouse == null ? null : GudangModel(id: warehouse, nama: 'Gudang $warehouse'),
);
class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth(UserModel user) : super(AuthState.authenticated(user));
  void changeUser(UserModel user) => state = AuthState.authenticated(user);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
class _Repository implements GudangRepository {
  List<RakModel> racks = [_rack(11, 1), _rack(12, 1), _rack(21, 2), _rack(13, 1, status: 'NONAKTIF')];
  Future<List<RakModel>> Function()? load;
  final targets = <int?>[];
  int submissions = 0;
  int? submittedTarget;
  List<Map<String, dynamic>>? submittedItems;
  bool reject = true;
  @override
  Future<List<RakModel>> getDaftarRak({String? cari, int? gudangId}) async {
    targets.add(gudangId);
    return load == null ? racks : await load!();
  }
  @override
  Future<Map<String, dynamic>> submitPenerimaanPo({required int poId,
    required int gudangId, required String nomorSuratJalan, String? catatan,
    required List<Map<String, dynamic>> items}) async {
    submissions++;
    submittedTarget = gudangId;
    submittedItems = items;
    if (reject) throw ApiException(message: 'Rak sudah tidak aktif, pilih ulang.', statusCode: 422);
    return {'kode_rcv': 'RCV-UJI'};
  }
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
Finder get _save => find.widgetWithText(CustomButton, 'Simpan ke Stok Gudang');
Finder _rackField([int itemId = 1]) => find.byKey(ValueKey('pilih-rak-$itemId'));
Finder get _targetDropdown => find.byKey(const ValueKey('gudang-penerimaan-selector'));
Future<void> _choose(WidgetTester tester, Finder dropdown, String text) async {
  await tester.ensureVisible(dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(text).last);
  await tester.pumpAndSettle();
}
Future<void> _openRack(WidgetTester tester, {int itemId = 1}) async {
  await tester.ensureVisible(_rackField(itemId));
  await tester.tap(_rackField(itemId));
  await tester.pumpAndSettle();
}

Finder _input(String hint) => find.byWidgetPredicate(
  (w) => w is TextField && w.decoration?.hintText == hint,
);

Finder _item(int itemId) => find.ancestor(
  of: _rackField(itemId),
  matching: find.byType(InboundItemDraftTile),
);

Future<void> _setQuantity(WidgetTester tester, int itemId, String value) async {
  final field = find.descendant(
    of: find.descendant(of: _item(itemId), matching: find.byType(AppQuantityStepper)).first,
    matching: find.byType(TextField),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}

Future<void> _dismissSheet(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}
Future<void> _enter(WidgetTester tester, String hint, String value) async {
  final field = _input(hint);
  await tester.ensureVisible(field);
  await tester.enterText(field, value);
  await tester.pump();
  // AppSearchBar memakai debounce 300 ms; majukan agar filter rak diterapkan.
  await tester.pump(const Duration(milliseconds: 350));
}
Future<void> _pump(WidgetTester tester, _Repository repository, UserModel user,
  {Future<List<GudangModel>> Function()? warehouses, _Auth? auth, double width = 400,
  PoInboundHeaderModel po = _po}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() { tester.view.resetPhysicalSize(); tester.view.resetDevicePixelRatio(); });
  await tester.pumpWidget(ProviderScope(overrides: [
    authStateProvider.overrideWith((ref) => auth ?? _Auth(user)),
    gudangRepositoryProvider.overrideWithValue(repository),
    masterGudangListProvider.overrideWith((ref) async => warehouses == null ? _warehouses : await warehouses()),
  ], child: MaterialApp(home: FormPenerimaanPoScreen(po: po))));
  await tester.pump();
  await tester.pump();
}
void main() {
  testWidgets('assigned admin is locked, racks scoped and never auto-picked at 320px', (tester) async {
    final repo = _Repository();
    await _pump(tester, repo, _user(role: 'admin_logistik'), width: 320);
    await tester.pumpAndSettle();
    expect(_targetDropdown, findsNothing);
    expect(repo.targets, [1]);
    expect(find.text('Pilih rak simpan'), findsOneWidget);
    expect(tester.widget<CustomButton>(_save).onPressed, isNull);
    await _openRack(tester);
    expect(find.text('RAK-11 (Rak 11)'), findsWidgets);
    expect(find.text('RAK-12 (Rak 12)'), findsWidgets);
    expect(find.text('RAK-21 (Rak 21)'), findsNothing);
    expect(find.text('RAK-13 (Rak 13)'), findsNothing);
    expect(tester.takeException(), isNull);
    await _dismissSheet(tester);
  });

  for (final role in ['super_admin', 'admin_logistik']) {
    testWidgets('$role without assignment must choose target before loading racks', (tester) async {
      final repo = _Repository();
      await _pump(tester, repo, _user(role: role, warehouse: null));
      await tester.pumpAndSettle();
      expect(repo.targets, isEmpty);
      expect(tester.widget<CustomButton>(_save).onPressed, isNull);
      await _choose(tester, _targetDropdown, 'Gudang Umum');
      expect(repo.targets, [2]);
      expect(find.text('Pilih rak simpan'), findsOneWidget);
    });
  }

  testWidgets('dashboard permission does not grant global warehouse selection; rejection stays available', (tester) async {
    final repo = _Repository();
    await _pump(tester, repo, _user(warehouse: null, permissions: ['page_AdminLogistikDashboard']));
    await tester.pumpAndSettle();
    expect(repo.targets, isEmpty);
    expect(_targetDropdown, findsNothing);
    expect(find.text('Penugasan gudang belum tersedia. Hubungi administrator.'), findsOneWidget);
    expect(tester.widget<CustomButton>(_save).onPressed, isNull);
    expect(tester.widget<CustomButton>(find.widgetWithText(CustomButton, 'Tolak Kiriman Vendor')).onPressed, isNotNull);
    expect(repo.submissions, 0);
  });

  testWidgets('target switch clears rack on zero quantity draft but preserves all other inputs', (tester) async {
    final repo = _Repository();
    await _pump(tester, repo, _user(role: 'super_admin', warehouse: null));
    await tester.pumpAndSettle();
    await _choose(tester, _targetDropdown, 'Gudang Medis');
    await _choose(tester, _rackField(), 'RAK-11 (Rak 11)');
    await _enter(tester, 'misal: B-1234', 'BATCH-TETAP');
    await _enter(tester, 'misal: SJ/PT-SLM/2026/089', 'SJ-TETAP');
    await _enter(tester, 'Kondisi segel kardus, nama kurir, atau ekspedisi...', 'CATATAN-TETAP');
    await tester.ensureVisible(find.text('Non-Exp'));
    await tester.tap(find.text('Non-Exp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final date = tester.widget<Text>(
      find.descendant(of: _item(1), matching: find.textContaining(RegExp(r'^\d{4}-\d{2}-\d{2}$'))),
    ).data!;
    await _setQuantity(tester, 1, '0');
    await _choose(tester, _targetDropdown, 'Gudang Umum');
    expect(find.descendant(of: _rackField(), matching: find.text('Pilih rak simpan')), findsOneWidget);
    expect(find.descendant(of: _item(1), matching: find.text('Stok bersih: 0 Box')), findsOneWidget);
    expect(find.text('BATCH-TETAP'), findsOneWidget);
    expect(find.text(date), findsOneWidget);
    expect(find.text('SJ-TETAP'), findsOneWidget);
    expect(find.text('CATATAN-TETAP'), findsOneWidget);
    await _setQuantity(tester, 1, '2');
    expect(tester.widget<CustomButton>(_save).onPressed, isNull);
    await _choose(tester, _rackField(), 'RAK-21 (Rak 21)');
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(repo.submittedTarget, 2);
    expect(repo.submittedItems!.single['jumlah_diterima'], 2);
    expect(repo.submittedItems!.single['nomor_batch'], 'BATCH-TETAP');
    expect(repo.submittedItems!.single['tanggal_kedaluwarsa'], date);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('account change clears rack without losing batch or quantities', (tester) async {
    final repo = _Repository();
    final auth = _Auth(_user());
    await _pump(tester, repo, _user(), auth: auth);
    await tester.pumpAndSettle();
    await _choose(tester, _rackField(), 'RAK-11 (Rak 11)');
    await _enter(tester, 'misal: B-1234', 'BATCH-AKUN');
    auth.changeUser(_user(id: 2, warehouse: 2));
    await tester.pumpAndSettle();
    expect(find.descendant(of: _rackField(), matching: find.text('Pilih rak simpan')), findsOneWidget);
    expect(find.text('BATCH-AKUN'), findsOneWidget);
    expect(find.text('Stok bersih: 5 Box'), findsOneWidget);
    expect(repo.targets.last, 2);
  });

  for (final state in ['loading', 'error', 'empty']) {
    testWidgets('rack $state prevents submit and offers status/retry', (tester) async {
      final repo = _Repository();
      repo.load = () => switch (state) {
        'loading' => Completer<List<RakModel>>().future,
        'error' => Future.error(Exception('offline')),
        _ => Future.value([]),
      };
      await _pump(tester, repo, _user());
      if (state != 'loading') await tester.pumpAndSettle();
      expect(tester.widget<CustomButton>(_save).onPressed, isNull);
      expect(repo.submissions, 0);
      expect(find.text(switch (state) {
        'loading' => 'Memuat rak gudang...',
        'error' => 'Gagal memuat rak gudang.',
        _ => 'Tidak ada rak aktif di gudang penerima.',
      }), findsOneWidget);
      if (state != 'loading') {
        repo.load = null;
        await tester.ensureVisible(find.text('Coba lagi rak'));
        await tester.tap(find.text('Coba lagi rak'));
        await tester.pumpAndSettle();
        expect(_rackField(), findsOneWidget);
      }
    });
    testWidgets('warehouse $state prevents rack loading and submit', (tester) async {
      final repo = _Repository();
      await _pump(tester, repo, _user(), warehouses: () => switch (state) {
        'loading' => Completer<List<GudangModel>>().future,
        'error' => Future.error(Exception('offline')),
        _ => Future.value([]),
      });
      if (state != 'loading') await tester.pumpAndSettle();
      expect(tester.widget<CustomButton>(_save).onPressed, isNull);
      expect(repo.targets, isEmpty);
      expect(repo.submissions, 0);
    });
  }

  testWidgets('assigned warehouse absent from active master list stays blocked', (tester) async {
    final repo = _Repository();
    await _pump(tester, repo, _user(role: 'super_admin', warehouse: 3));
    await tester.pumpAndSettle();
    expect(_targetDropdown, findsNothing);
    expect(repo.targets, isEmpty);
    expect(find.text('Gudang penugasan tidak aktif atau tidak tersedia. Hubungi administrator.'), findsOneWidget);
    expect(tester.widget<CustomButton>(_save).onPressed, isNull);
    expect(repo.submissions, 0);
  });

  testWidgets('searched rack updates only its opening item and keeps two drafts independent', (tester) async {
    final repo = _Repository();
    final po = PoInboundHeaderModel(
      id: _po.id, kodePo: _po.kodePo, pemasok: _po.pemasok,
      tanggalPo: _po.tanggalPo, status: _po.status, totalItem: 2,
      items: [
        _po.items.first,
        const PoInboundItemModel(
          id: 2, barangId: 2, kodeBarang: 'BRG-2', namaBarang: 'Masker',
          satuan: 'Box', jumlahDipesan: 4, jumlahSudahDiterima: 0,
          sisaKebutuhan: 4, hargaSatuan: 200,
        ),
      ],
    );
    await _pump(tester, repo, _user(), po: po);
    await tester.pumpAndSettle();
    await _enter(tester, 'misal: SJ/PT-SLM/2026/089', 'SJ-DUA-ITEM');
    await _enter(tester, 'Kondisi segel kardus, nama kurir, atau ekspedisi...', 'CATATAN-DUA-ITEM');
    for (final id in [1, 2]) {
      final batch = find.descendant(of: _item(id), matching: _input('misal: B-1234'));
      await tester.ensureVisible(batch);
      await tester.enterText(batch, 'BATCH-$id');
      await _setQuantity(tester, id, '${id + 1}');
    }
    await _openRack(tester, itemId: 2);
    expect(find.text('Gudang Penerima: Gudang Medis'), findsOneWidget);
    await _enter(tester, 'Cari kode atau nama rak...', '  rAk 12  ');
    await tester.pumpAndSettle();
    expect(find.text('RAK-11 (Rak 11)'), findsNothing);
    expect(find.text('Gudang: Gudang 1'), findsOneWidget);
    await tester.tap(find.text('RAK-12 (Rak 12)'));
    await tester.pumpAndSettle();
    expect(find.descendant(of: _rackField(2), matching: find.text('RAK-12 (Rak 12)')), findsOneWidget);
    expect(find.descendant(of: _rackField(2), matching: find.text('Gudang: Gudang 1')), findsOneWidget);
    expect(find.descendant(of: _rackField(1), matching: find.text('Pilih rak simpan')), findsOneWidget);
    expect(tester.widget<CustomButton>(_save).onPressed, isNull);
    await _choose(tester, _rackField(1), 'RAK-11 (Rak 11)');
    expect(find.descendant(of: _rackField(2), matching: find.text('RAK-12 (Rak 12)')), findsOneWidget);
    expect(repo.targets, [1]);
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(repo.submittedItems, [
      containsPair('lokasi_gudang_id', 11),
      containsPair('lokasi_gudang_id', 12),
    ]);
    expect(repo.submittedItems!.map((item) => item['jumlah_diterima']), [2, 3]);
    expect(repo.submittedItems!.map((item) => item['nomor_batch']), ['BATCH-1', 'BATCH-2']);
    expect(find.text('SJ-DUA-ITEM'), findsOneWidget);
    expect(find.text('CATATAN-DUA-ITEM'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final change in ['target', 'account']) {
    testWidgets('$change changes while sheet is open reject old results even after returning to original context', (tester) async {
      final repo = _Repository();
      final auth = _Auth(_user());
      await _pump(tester, repo, _user(), auth: auth);
      await tester.pumpAndSettle();
      await _enter(tester, 'misal: B-1234', 'BATCH-KONTEKS');
      await _enter(tester, 'misal: SJ/PT-SLM/2026/089', 'SJ-KONTEKS');
      await _enter(tester, 'Kondisi segel kardus, nama kurir, atau ekspedisi...', 'CATATAN-KONTEKS');
      await _setQuantity(tester, 1, '3');
      await _choose(tester, _rackField(), 'RAK-11 (Rak 11)');
      await _openRack(tester);
      await _enter(tester, 'Cari kode atau nama rak...', 'RAK-12');
      await tester.pumpAndSettle();
      final refreshed = Completer<List<RakModel>>();
      repo.load = () => refreshed.future;
      auth.changeUser(change == 'target' ? _user(warehouse: 2) : _user(id: 2));
      await tester.pump();
      auth.changeUser(_user());
      await tester.pump();
      refreshed.complete(repo.racks);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('RAK-12 (Rak 12)'));
      await tester.tap(find.text('RAK-12 (Rak 12)'));
      await tester.pumpAndSettle();
      expect(find.descendant(of: _rackField(), matching: find.text('Pilih rak simpan')), findsOneWidget);
      expect(tester.widget<CustomButton>(_save).onPressed, isNull);
      expect(find.text('Stok bersih: 3 Box'), findsOneWidget);
      expect(find.text('BATCH-KONTEKS'), findsOneWidget);
      expect(find.text('SJ-KONTEKS'), findsOneWidget);
      expect(find.text('CATATAN-KONTEKS'), findsOneWidget);
      expect(repo.submissions, 0);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  for (final change in ['inactive', 'moved', 'missing']) {
    testWidgets('refreshed $change rack cannot be selected or submitted from an open sheet', (tester) async {
      final repo = _Repository();
      await _pump(tester, repo, _user());
      await tester.pumpAndSettle();
      await _enter(tester, 'misal: SJ/PT-SLM/2026/089', 'SJ-REFRESH');
      await _enter(tester, 'misal: B-1234', 'BATCH-REFRESH');
      await _choose(tester, _rackField(), 'RAK-11 (Rak 11)');
      expect(tester.widget<CustomButton>(_save).onPressed, isNotNull);
      await _openRack(tester);
      final refreshed = Completer<List<RakModel>>();
      repo.load = () => refreshed.future;
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FormPenerimaanPoScreen)),
      );
      container.invalidate(rakPenerimaanProvider(1));
      await tester.pump();
      await tester.pump();
      expect(repo.submissions, 0);
      refreshed.complete([
        _rack(12, 1),
        if (change == 'inactive') _rack(11, 1, status: 'NONAKTIF'),
        if (change == 'moved') _rack(11, 2),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('RAK-11 (Rak 11)'), findsNothing);
      expect(find.text('RAK-12 (Rak 12)'), findsOneWidget);
      await _dismissSheet(tester);
      expect(find.text('Pilih rak simpan'), findsOneWidget);
      expect(tester.widget<CustomButton>(_save).onPressed, isNull);
      await tester.tap(_save);
      await tester.pump();
      expect(repo.submissions, 0);
      expect(find.text('BATCH-REFRESH'), findsOneWidget);
      expect(find.text('Stok bersih: 5 Box'), findsOneWidget);
      await _choose(tester, _rackField(), 'RAK-12 (Rak 12)');
      expect(tester.widget<CustomButton>(_save).onPressed, isNotNull);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('422 refreshes warehouses and racks, preserves input and rejects stale selection', (tester) async {
    final repo = _Repository();
    var warehouseLoads = 0;
    await _pump(tester, repo, _user(), warehouses: () async { warehouseLoads++; return _warehouses; });
    await tester.pumpAndSettle();
    await _enter(tester, 'misal: SJ/PT-SLM/2026/089', 'SJ-422');
    await _enter(tester, 'Kondisi segel kardus, nama kurir, atau ekspedisi...', 'CATATAN-422');
    await _enter(tester, 'misal: B-1234', 'BATCH-422');
    await _choose(tester, _rackField(), 'RAK-11 (Rak 11)');
    repo.racks = [_rack(12, 1)];
    await tester.tap(_save);
    await tester.pumpAndSettle();
    expect(repo.submissions, 1);
    expect(warehouseLoads, 2);
    expect(repo.targets.where((target) => target == 1).length, greaterThanOrEqualTo(2));
    expect(find.text('SJ-422'), findsOneWidget);
    expect(find.text('CATATAN-422'), findsOneWidget);
    expect(find.text('BATCH-422'), findsOneWidget);
    expect(find.text('Pilih rak simpan'), findsOneWidget);
    expect(find.text('Stok bersih: 5 Box'), findsOneWidget);
    expect(tester.widget<CustomButton>(_save).onPressed, isNull);
    expect(repo.submissions, 1);
    await _choose(tester, _rackField(), 'RAK-12 (Rak 12)');
    expect(tester.widget<CustomButton>(_save).onPressed, isNotNull);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
