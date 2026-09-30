import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/distribusi/data/models/sppb_model.dart';
import 'package:simlog_mobile/features/distribusi/data/repositories/distribusi_repository.dart';
import 'package:simlog_mobile/features/distribusi/presentation/providers/distribusi_provider.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDistribusiRepository implements DistribusiRepository {
  bool getAntreanPickingCalled = false;

  @override
  Future<List<PickingAntreanModel>> getAntreanPicking() async {
    getAntreanPickingCalled = true;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('antreanPickingProvider returns empty list without calling API for Kepala Unit', () async {
    const karuUser = UserModel(
      id: 6,
      name: 'dr. Pratama, Sp.EM',
      email: 'kepalaunit@simlogrs.local',
      roles: ['kepala_unit'],
      permissions: ['page_KepalaUnitDashboard', 'view_any_layanan_unit::approval::karu'],
    );

    final fakeRepo = FakeDistribusiRepository();

    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => MockAuthNotifier(karuUser)),
        distribusiRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(antreanPickingProvider.future);

    expect(result, isEmpty);
    expect(fakeRepo.getAntreanPickingCalled, isFalse);
  });

  test('antreanPickingProvider calls API for Petugas Gudang', () async {
    const gudangUser = UserModel(
      id: 4,
      name: 'Joko Wahyudi, A.Md.',
      email: 'petugasgudang@simlogrs.local',
      roles: ['petugas_gudang'],
      permissions: ['page_GudangDashboard', 'create_gudang_stok::picking::distribusi'],
    );

    final fakeRepo = FakeDistribusiRepository();

    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => MockAuthNotifier(gudangUser)),
        distribusiRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(antreanPickingProvider.future);

    expect(result, isEmpty);
    expect(fakeRepo.getAntreanPickingCalled, isTrue);
  });
}
