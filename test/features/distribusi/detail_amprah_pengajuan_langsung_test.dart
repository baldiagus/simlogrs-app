import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/distribusi/data/models/amprah_model.dart';
import 'package:simlog_mobile/features/distribusi/presentation/providers/distribusi_provider.dart';
import 'package:simlog_mobile/features/distribusi/presentation/screens/detail_amprah_screen.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

AmprahHeaderModel _amprah(String status) => AmprahHeaderModel(
      id: 7,
      kode: 'REQ-202610-KT',
      unit: 'Instalasi Pemeliharaan Sarana',
      gudang: 'Gudang Logistik',
      pengaju: 'Kepala Teknisi',
      tanggalPermintaan: '2026-10-15',
      urgensi: 'REGULER',
      status: status,
      canCancel: false,
      jumlahItem: 0,
      items: const [],
    );

Future<void> _pumpDetail(WidgetTester tester, AmprahHeaderModel amprah, UserModel user) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => MockAuthNotifier(user)),
        detailAmprahProvider(amprah.id).overrideWith((ref) => Future.value(amprah)),
      ],
      child: MaterialApp(
        home: DetailAmprahScreen(amprahId: amprah.id, kodeAmprah: amprah.kode),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const kepalaTeknisi = UserModel(
    id: 11,
    name: 'Kepala Teknisi',
    email: 'kt@simlogrs.local',
    roles: ['kepala_teknisi'],
    permissions: [],
  );

  testWidgets('pengajuan langsung kepala teknisi (DISETUJUI_KARU) menandai Tahap 1 selesai', (tester) async {
    expect(kepalaTeknisi.isKaru, isTrue);

    await _pumpDetail(tester, _amprah('DISETUJUI_KARU'), kepalaTeknisi);

    expect(find.text('Tahap 1: Persetujuan Kepala Ruangan (Karu)'), findsOneWidget);
    expect(find.text('Disetujui Karu'), findsOneWidget);
    expect(find.text('Menunggu persetujuan Karu'), findsNothing);
    // Tahap 1 selesai (ceklis), Tahap 2 aktif menunggu gudang.
    expect(find.byIcon(LucideIcons.checkCircle2), findsOneWidget);
    expect(find.text('Menunggu verifikasi stok gudang'), findsOneWidget);
  });

  testWidgets('amprah DIBATALKAN tidak ditandai Disetujui Karu', (tester) async {
    await _pumpDetail(tester, _amprah('DIBATALKAN'), kepalaTeknisi);

    expect(find.text('Dibatalkan'), findsOneWidget);
    expect(find.text('Disetujui Karu'), findsNothing);
    expect(find.byIcon(LucideIcons.checkCircle2), findsNothing);
  });

  test('payload pengajuan amprah tidak mengirim status (ditentukan backend)', () {
    final item = AmprahCartDraftItem(
      barang: const BarangAmprahKatalogModel(
        id: 1,
        kode: 'BRG-1',
        nama: 'Kabel NYM',
        tipe: 'HABIS_PAKAI',
        tipeLabel: 'Habis Pakai',
        kategori: 'Listrik',
        satuan: 'Roll',
        merek: '-',
        stokTersedia: 5,
      ),
      jumlah: 2,
    );

    expect(item.toSubmissionJson().containsKey('status'), isFalse);
  });
}
