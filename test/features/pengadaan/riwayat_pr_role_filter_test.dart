import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/pengadaan/data/models/pr_model.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/providers/pengadaan_provider.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/screens/form_pengajuan_pr_screen.dart';
import 'package:simlog_mobile/features/pengadaan/presentation/screens/riwayat_pr_screen.dart';

class TestAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  TestAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final mockPrList = [
    const PrHeaderModel(
      id: 1,
      kode: 'PR-2026-09-0001',
      unit: 'Ruang ICU Bedah',
      pengaju: 'Ns. Ratna',
      tanggalPermintaan: '24/09/2026',
      urgensi: 'REGULER',
      status: 'DIAJUKAN',
      jumlahItem: 3,
      items: [],
    ),
    const PrHeaderModel(
      id: 2,
      kode: 'PR-2026-09-0002',
      unit: 'Instalasi Farmasi',
      pengaju: 'apt. Budi',
      tanggalPermintaan: '25/09/2026',
      urgensi: 'CITO',
      status: 'DISETUJUI_KARU',
      jumlahItem: 5,
      items: [],
    ),
    const PrHeaderModel(
      id: 3,
      kode: 'PR-2026-09-0003',
      unit: 'Instalasi Rawat Inap',
      pengaju: 'dr. Siti',
      tanggalPermintaan: '25/09/2026',
      urgensi: 'REGULER',
      status: 'DITERUSKAN_KE_PENGADAAN',
      jumlahItem: 2,
      items: [],
    ),
  ];

  const pengadaanUser = UserModel(
    id: 10,
    name: 'Petugas Pengadaan',
    email: 'pengadaan@simlog.id',
    roles: ['pengadaan'],
    permissions: [],
  );

  const unitUser = UserModel(
    id: 20,
    name: 'Petugas Ruangan',
    email: 'unit@simlog.id',
    roles: ['petugas_unit'],
    permissions: ['create_pengadaan::permintaan::pengadaan'],
  );

  const karuUser = UserModel(
    id: 30,
    name: 'dr. Hendra (Karu)',
    email: 'karu@simlog.id',
    roles: ['kepala_unit'],
    permissions: ['create_pengadaan::permintaan::pengadaan'],
  );

  testWidgets('Role Pengadaan hanya melihat PR berstatus disetujui, menyembunyikan DIAJUKAN', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => TestAuthNotifier(pengadaanUser)),
          daftarPrProvider.overrideWith((ref) => Future.value(mockPrList)),
        ],
        child: const MaterialApp(
          home: RiwayatPrScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PR-2026-09-0001'), findsNothing); // Status DIAJUKAN disembunyikan
    expect(find.text('PR-2026-09-0002'), findsOneWidget); // Status DISETUJUI_KARU tampil
    expect(find.text('PR-2026-09-0003'), findsOneWidget); // Status DITERUSKAN tampil
    expect(find.text('Ajukan PR Baru'), findsNothing); // Pengadaan tidak melihat FAB
  });

  testWidgets('Role Unit melihat seluruh riwayat pengajuan PR termasuk DIAJUKAN', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => TestAuthNotifier(unitUser)),
          daftarPrProvider.overrideWith((ref) => Future.value(mockPrList)),
        ],
        child: const MaterialApp(
          home: RiwayatPrScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PR-2026-09-0001'), findsOneWidget);
    expect(find.text('PR-2026-09-0002'), findsOneWidget);
    expect(find.text('PR-2026-09-0003'), findsOneWidget);
    expect(find.text('Ajukan PR Baru'), findsOneWidget);
  });

  testWidgets('FormPengajuanPrScreen menampilkan banner jalur Karu dan tombol langsung ke Pengadaan', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => TestAuthNotifier(karuUser)),
        ],
        child: const MaterialApp(
          home: FormPengajuanPrScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Jalur Karu: PR langsung disetujui & diteruskan ke Pengadaan'), findsOneWidget);
    expect(find.text('Ajukan & Teruskan ke Pengadaan'), findsOneWidget);
  });

  testWidgets('FormPengajuanPrScreen untuk staf biasa tidak menampilkan banner Karu', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => TestAuthNotifier(unitUser)),
        ],
        child: const MaterialApp(
          home: FormPengajuanPrScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Jalur Karu'), findsNothing);
    expect(find.text('Kirim Pengajuan PR'), findsOneWidget);
  });
}
