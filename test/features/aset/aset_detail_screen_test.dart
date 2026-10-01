import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/aset/data/models/aset_detail_model.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/aset_detail_screen.dart';
import 'package:simlog_mobile/features/aset/presentation/screens/histori_sirkulasi_aset_screen.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('AsetDetailScreen renders without overflow on narrow 320px viewport', (tester) async {
    const detail = AsetDetailModel(
      id: 1,
      kodeAset: 'AST-MED-2026-0001',
      nomorSeri: 'SN-VENT-9921',
      namaKomoditas: 'Ventilator Transport ICU Dewasa & Anak',
      kategori: 'Alat Kesehatan Medik',
      merek: 'Hamilton Medical',
      spesifikasi: 'Model T1, Battery Backup 4 Hours',
      status: 'DIPINJAM',
      kondisi: 'BAIK',
      lokasiTercatat: 'Ruang ICU Bedah Lt. 2',
      penanggungJawab: 'Ns. Ratna Sari, S.Kep',
      nilaiPerolehan: 450000000,
      tanggalPerolehan: '15/01/2024',
      totalRiwayatServis: 5,
      servisTerakhir: ServisTerakhirInfo(
        kode: 'SRV-2026-0312-PANJANG',
        status: 'SELESAI',
        prioritas: 'TINGGI',
        deskripsi: 'Kalibrasi sensor flow dan penggantian filter O2 berkala.',
        tanggalPengajuan: '20/09/2026',
      ),
      peminjamanAktif: PeminjamanAktifInfo(
        peminjamanId: 10,
        kodePinjam: 'PJM-2026-0044',
        unitPeminjam: 'Instalasi Gawat Darurat',
        tanggalKembaliRencana: '2026-10-01',
        isOverdue: false,
      ),
      riwayatPeminjaman: [
        RiwayatPeminjamanAsetItemModel(
          id: 1,
          kodePeminjaman: 'PINJ-2026-002',
          unitPeminjam: 'Instalasi Gawat Darurat',
          peminjam: 'dr. Pratama, Sp.EM',
          tanggalPinjam: '2026-09-24',
          tanggalKembaliRencana: '2026-10-01',
          tanggalKembaliAktual: '2026-09-24',
          status: 'SELESAI',
          keperluan: 'Peminjaman Darurat Pasien Syok Kardiogenik',
          kondisiSaatPinjam: 'BAIK',
          kondisiSaatKembali: 'BAIK',
          catatanPengembalian: 'Alat berfungsi normal dan telah disanitasi',
          pemeriksaKembali: 'dr. Pratama, Sp.EM',
        ),
      ],
    );

    // Set screen size to 320x640 (narrow constraint causing the original ~286px content width)
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AsetDetailScreen(initialAset: detail),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Histori Pemeliharaan (IPSRS)'), findsOneWidget);
    expect(find.text('5x Servis'), findsOneWidget);
    expect(find.text('Histori Sirkulasi (Peminjaman)'), findsOneWidget);
    expect(find.text('Kembalikan Fisik'), findsOneWidget);

    // Scroll down to the riwayat peminjaman card and tap
    final cardFinder = find.text('Histori Sirkulasi (Peminjaman)');
    await tester.scrollUntilVisible(cardFinder, 200);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    expect(find.byType(HistoriSirkulasiAsetScreen), findsOneWidget);
    expect(find.text('Buku Catatan Sirkulasi Unit'), findsOneWidget);
  });
  testWidgets('AsetDetailScreen hides Ajukan Peminjaman button if asset belongs to user unit', (tester) async {
    const userIgd = UserModel(
      id: 6,
      name: 'dr. Pratama, Sp.EM',
      email: 'kepalaunit@simlogrs.local',
      roles: ['kepala_unit'],
      permissions: ['page_KepalaUnitDashboard'],
      unit: UnitModel(id: 1, nama: 'Instalasi Gawat Darurat', kode: 'IGD'),
    );

    const asetInIgd = AsetDetailModel(
      id: 1,
      kodeAset: 'AST-2026-001',
      nomorSeri: 'PRINTER-IGD-1',
      namaKomoditas: 'Printer Epson L3210',
      kategori: 'Elektronik & Komputer',
      merek: 'Epson',
      spesifikasi: 'All-in-one printer',
      status: 'TERSEDIA',
      kondisi: 'BAIK',
      lokasiTercatat: 'Instalasi Gawat Darurat',
      penanggungJawab: 'Instalasi Gawat Darurat',
      nilaiPerolehan: 2500000,
      tanggalPerolehan: '2026-09-20',
      totalRiwayatServis: 0,
      unitId: 1,
    );

    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(userIgd)),
        ],
        child: const MaterialApp(
          home: AsetDetailScreen(initialAset: asetInIgd),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Button Ajukan Peminjaman Aset MUST NOT be shown for own room's asset
    expect(find.text('Ajukan Peminjaman Aset'), findsNothing);
    expect(find.text('Lapor Kerusakan Alat (IPSRS)'), findsOneWidget);
  });

  testWidgets('AsetDetailScreen shows Ajukan Peminjaman button if asset belongs to another unit', (tester) async {
    const userIgd = UserModel(
      id: 6,
      name: 'dr. Pratama, Sp.EM',
      email: 'kepalaunit@simlogrs.local',
      roles: ['kepala_unit'],
      permissions: ['page_KepalaUnitDashboard'],
      unit: UnitModel(id: 1, nama: 'Instalasi Gawat Darurat', kode: 'IGD'),
    );

    const asetInDireksi = AsetDetailModel(
      id: 3,
      kodeAset: 'AST-2026-003',
      nomorSeri: 'PRINTER-MJN-1',
      namaKomoditas: 'Printer Epson L3210',
      kategori: 'Elektronik & Komputer',
      merek: 'Epson',
      spesifikasi: 'All-in-one printer',
      status: 'TERSEDIA',
      kondisi: 'BAIK',
      lokasiTercatat: 'Direktorat & Manajemen Eksekutif',
      penanggungJawab: 'Direktorat & Manajemen Eksekutif',
      nilaiPerolehan: 2500000,
      tanggalPerolehan: '2026-09-20',
      totalRiwayatServis: 0,
      unitId: 8,
    );

    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(userIgd)),
        ],
        child: const MaterialApp(
          home: AsetDetailScreen(initialAset: asetInDireksi),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Button Ajukan Peminjaman Aset MUST be shown for other unit's asset
    expect(find.text('Ajukan Peminjaman Aset'), findsOneWidget);
    // Button Lapor Kerusakan MUST NOT be shown for other unit's asset
    expect(find.text('Lapor Kerusakan Alat (IPSRS)'), findsNothing);
  });

  testWidgets('AsetDetailScreen shows Lapor Kerusakan if asset is currently borrowed by user unit', (tester) async {
    const userIgd = UserModel(
      id: 6,
      name: 'dr. Pratama, Sp.EM',
      email: 'kepalaunit@simlogrs.local',
      roles: ['kepala_unit'],
      permissions: ['page_KepalaUnitDashboard'],
      unit: UnitModel(id: 1, nama: 'Instalasi Gawat Darurat', kode: 'IGD'),
    );

    const asetBorrowedByIgd = AsetDetailModel(
      id: 3,
      kodeAset: 'AST-2026-003',
      nomorSeri: 'PRINTER-MJN-1',
      namaKomoditas: 'Printer Epson L3210',
      kategori: 'Elektronik & Komputer',
      merek: 'Epson',
      spesifikasi: 'All-in-one printer',
      status: 'DIPINJAM',
      kondisi: 'BAIK',
      lokasiTercatat: 'Instalasi Gawat Darurat',
      penanggungJawab: 'Instalasi Gawat Darurat',
      nilaiPerolehan: 2500000,
      tanggalPerolehan: '2026-09-20',
      totalRiwayatServis: 0,
      unitId: 8, // Origin: Direksi
      peminjamanAktif: PeminjamanAktifInfo(
        peminjamanId: 10,
        kodePinjam: 'PINJ-2026-002',
        unitPeminjam: 'Instalasi Gawat Darurat',
        isOverdue: false,
      ),
    );

    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(userIgd)),
        ],
        child: const MaterialApp(
          home: AsetDetailScreen(initialAset: asetBorrowedByIgd),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Asset is on loan to user's unit: can report damage
    expect(find.text('Lapor Kerusakan Alat (IPSRS)'), findsOneWidget);
    // Cannot borrow an already borrowed asset
    expect(find.text('Ajukan Peminjaman Aset'), findsNothing);
  });

  testWidgets('AsetDetailScreen hides Ajukan Peminjaman and shows banner if asset has pending loan request by another unit', (tester) async {
    const userIgd = UserModel(
      id: 6,
      name: 'dr. Pratama, Sp.EM',
      email: 'kepalaunit@simlogrs.local',
      roles: ['kepala_unit'],
      permissions: ['page_KepalaUnitDashboard'],
      unit: UnitModel(id: 1, nama: 'Instalasi Gawat Darurat', kode: 'IGD'),
    );

    const asetPendingLoan = AsetDetailModel(
      id: 4,
      kodeAset: 'AST-2026-004',
      nomorSeri: 'PRINTER-AUD-1',
      namaKomoditas: 'Printer Epson L3210',
      kategori: 'Elektronik & Komputer',
      merek: 'Epson',
      spesifikasi: 'All-in-one printer',
      status: 'TERSEDIA',
      kondisi: 'BAIK',
      lokasiTercatat: 'Satuan Pengawas Internal (SPI)',
      penanggungJawab: 'Satuan Pengawas Internal (SPI)',
      nilaiPerolehan: 2500000,
      tanggalPerolehan: '2026-09-20',
      totalRiwayatServis: 0,
      unitId: 9, // Origin: SPI
      isSedangDiajukan: true,
      statusSirkulasi: 'DIAJUKAN',
      antreanPeminjaman: {
        'peminjaman_id': 15,
        'kode_pinjam': 'PINJ-2026-009',
        'unit_peminjam': 'Direktorat & Manajemen Eksekutif',
        'pengaju': 'Drs. H. Mulyono',
        'status': 'DIAJUKAN',
      },
    );

    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(userIgd)),
        ],
        child: const MaterialApp(
          home: AsetDetailScreen(initialAset: asetPendingLoan),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Button Ajukan Peminjaman Aset MUST NOT be shown
    expect(find.text('Ajukan Peminjaman Aset'), findsNothing);
    // Banner Sedang Dalam Proses Peminjaman MUST be shown
    expect(find.text('Sedang Dalam Proses Peminjaman'), findsOneWidget);
    expect(find.textContaining('Direktorat & Manajemen Eksekutif'), findsOneWidget);
    expect(find.textContaining('PINJ-2026-009'), findsOneWidget);
  });
}
