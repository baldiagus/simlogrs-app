import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/gudang/data/models/po_inbound_model.dart';
import 'package:simlog_mobile/features/gudang/data/repositories/gudang_repository.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/gudang_provider.dart';
import 'package:simlog_mobile/features/gudang/presentation/providers/inbound_provider.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGudangRepository implements GudangRepository {
  bool getPoInboundListCalled = false;

  @override
  Future<List<PoInboundHeaderModel>> getPoInboundList() async {
    getPoInboundListCalled = true;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('daftarPoInboundProvider returns empty list without calling API for Pengadaan user', () async {
    const pengadaanUser = UserModel(
      id: 5,
      name: 'Siti Nurhaliza, S.E.',
      email: 'pengadaan@simlogrs.local',
      roles: ['pengadaan'],
      permissions: ['page_PengadaanDashboard', 'view_any_pengadaan::pesanan::pembelian'],
    );

    final fakeRepo = FakeGudangRepository();

    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => MockAuthNotifier(pengadaanUser)),
        gudangRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(daftarPoInboundProvider.future);

    expect(result, isEmpty);
    expect(fakeRepo.getPoInboundListCalled, isFalse);
  });

  test('daftarPoInboundProvider calls API for Petugas Gudang user', () async {
    const gudangUser = UserModel(
      id: 4,
      name: 'Joko Wahyudi, A.Md.',
      email: 'petugasgudang@simlogrs.local',
      roles: ['petugas_gudang'],
      permissions: ['page_GudangDashboard', 'create_gudang_stok::penerimaan::po'],
    );

    final fakeRepo = FakeGudangRepository();

    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => MockAuthNotifier(gudangUser)),
        gudangRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(daftarPoInboundProvider.future);

    expect(result, isEmpty);
    expect(fakeRepo.getPoInboundListCalled, isTrue);
  });
}
