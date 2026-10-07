import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/pengalihan_model.dart';
import 'package:simlog_mobile/features/aset/data/repositories/pengalihan_repository.dart';
import 'package:simlog_mobile/features/aset/presentation/providers/pengalihan_provider.dart';

class FakePengalihanRepo extends Fake implements PengalihanRepository {
  bool submitCalled = false;
  bool approveCalled = false;

  @override
  Future<Map<String, dynamic>> submitPengalihan(Map<String, dynamic> payload) async {
    submitCalled = true;
    return {'id': 1, 'kode': 'TRF-TEST', 'status': 'DIAJUKAN'};
  }

  @override
  Future<void> otorisasiPengalihan({required int id, required String aksi, String? catatan}) async {
    approveCalled = true;
  }

  @override
  Future<List<PengalihanItemModel>> getDaftarPengalihan({String tab = 'aktif'}) async {
    return [];
  }
}

void main() {
  test('PengalihanActionNotifier submits transfer and sets success state', () async {
    final fakeRepo = FakePengalihanRepo();
    final container = ProviderContainer(
      overrides: [
        pengalihanRepositoryProvider.overrideWithValue(fakeRepo),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(pengalihanActionProvider.notifier);
    final ok = await notifier.ajukanPengalihan({
      'tipe_tujuan': 'RUANGAN',
      'unit_tujuan_id': 4,
      'aset_ids': [10],
      'tanggal_pengalihan': '2026-10-07',
      'alasan': 'Relokasi alat ke ICU',
    });

    expect(ok, isTrue);
    expect(fakeRepo.submitCalled, isTrue);
    final state = container.read(pengalihanActionProvider);
    expect(state.successMessage, contains('berhasil diajukan'));
  });
}
