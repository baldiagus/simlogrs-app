import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/distribusi/data/models/amprah_model.dart';
import 'package:simlog_mobile/features/distribusi/data/repositories/distribusi_repository.dart';
import 'package:simlog_mobile/features/distribusi/presentation/providers/distribusi_provider.dart';
import 'package:simlog_mobile/features/distribusi/presentation/screens/amprah_hub_screen.dart';
import 'package:simlog_mobile/features/distribusi/presentation/screens/form_pengajuan_amprah_screen.dart';
import 'package:simlog_mobile/shared/widgets/custom_button.dart';
import 'package:simlog_mobile/shared/widgets/empty_state_view.dart';
import 'package:simlog_mobile/shared/widgets/status_badge.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDistribusiRepository implements DistribusiRepository {
  bool submitCalled = false;

  @override
  Future<Map<String, dynamic>> submitAmprah({
    int? gudangId,
    required String urgensi,
    String? catatan,
    required List<Map<String, dynamic>> items,
  }) async {
    submitCalled = true;
    return {'id': 99, 'kode': 'REQ-202610-099'};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AmprahHeaderModel - SEDANG_DIKIRIM parsing & DIBATALKAN removal', () {
    test('parses SEDANG_DIKIRIM correctly and marks isTahapKaruSelesai true', () {
      final json = {
        'id': 10,
        'kode': 'REQ-202610-010',
        'unit': 'Ruang Melati',
        'gudang': 'Gudang Sentral',
        'pengaju': 'Staf Melati',
        'tanggal_permintaan': '2026-10-16',
        'urgensi': 'CITO',
        'status': 'SEDANG_DIKIRIM',
        'can_cancel': false,
        'jumlah_item': 1,
        'items': [],
      };

      final header = AmprahHeaderModel.fromJson(json);

      expect(header.isSedangDikirim, isTrue);
      expect(header.isTahapKaruSelesai, isTrue);
      expect(header.isDiajukan, isFalse);
      expect(header.isDitolak, isFalse);
      expect(header.isSelesai, isFalse);
    });

    test('isTahapKaruSelesai false for DIAJUKAN and DITOLAK', () {
      final diajukan = AmprahHeaderModel.fromJson({
        'id': 1,
        'kode': 'REQ-1',
        'unit': 'Melati',
        'gudang': 'Sentral',
        'pengaju': 'Staf',
        'tanggal_permintaan': '2026-10-16',
        'urgensi': 'REGULER',
        'status': 'DIAJUKAN',
        'can_cancel': true,
        'jumlah_item': 0,
        'items': [],
      });
      expect(diajukan.isTahapKaruSelesai, isFalse);
      expect(diajukan.isDiajukan, isTrue);

      final ditolak = AmprahHeaderModel.fromJson({
        'id': 2,
        'kode': 'REQ-2',
        'unit': 'Melati',
        'gudang': 'Sentral',
        'pengaju': 'Staf',
        'tanggal_permintaan': '2026-10-16',
        'urgensi': 'REGULER',
        'status': 'DITOLAK',
        'can_cancel': false,
        'jumlah_item': 0,
        'items': [],
      });
      expect(ditolak.isTahapKaruSelesai, isFalse);
      expect(ditolak.isDitolak, isTrue);
    });
  });

  group('StatusBadge SEDANG_DIKIRIM', () {
    testWidgets('renders SEDANG_DIKIRIM label with space formatting', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusBadge(status: 'SEDANG_DIKIRIM'),
          ),
        ),
      );

      expect(find.text('SEDANG DIKIRIM'), findsOneWidget);
    });
  });

  group('AmprahHubScreen Filter Bar & FAB Guard', () {
    testWidgets('renders Dikirim filter pill for SEDANG_DIKIRIM', (tester) async {
      const userWithUnit = UserModel(
        id: 1,
        name: 'Staf Unit',
        email: 'unit@simlogrs.local',
        roles: ['petugas_unit'],
        permissions: ['create_layanan_unit::permintaan::barang'],
        unit: UnitModel(id: 1, nama: 'Ruang Melati'),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(userWithUnit)),
            daftarAmprahProvider.overrideWith((ref, params) => Future.value(<AmprahHeaderModel>[])),
            sppbInboundProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: AmprahHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dikirim'), findsOneWidget);
      expect(find.text('Ajukan Amprah'), findsOneWidget);
    });

    testWidgets('hides Ajukan Amprah FAB for user without unit and without gudang', (tester) async {
      const userWithoutScope = UserModel(
        id: 2,
        name: 'User Luar',
        email: 'luar@simlogrs.local',
        roles: ['super_admin'],
        permissions: [],
        unit: null,
        gudang: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(userWithoutScope)),
            daftarAmprahProvider.overrideWith((ref, params) => Future.value(<AmprahHeaderModel>[])),
            sppbInboundProvider.overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: AmprahHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ajukan Amprah'), findsNothing);
    });
  });

  group('FormPengajuanAmprahScreen EmptyStateView Guard', () {
    testWidgets('shows EmptyStateView and disables submit when user lacks unit and gudang', (tester) async {
      const userWithoutScope = UserModel(
        id: 3,
        name: 'User Tanpa Scope',
        email: 'tanpascope@simlogrs.local',
        roles: ['petugas_unit'],
        permissions: ['create_layanan_unit::permintaan::barang'],
        unit: null,
        gudang: null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => MockAuthNotifier(userWithoutScope)),
            katalogAmprahProvider.overrideWith((ref, query) => Future.value([])),
          ],
          child: const MaterialApp(
            home: FormPengajuanAmprahScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('Akun Anda belum terhubung dengan unit ruangan atau gudang'), findsOneWidget);

      final button = tester.widget<CustomButton>(find.byType(CustomButton));
      expect(button.onPressed, isNull);
    });
  });

  group('AmprahActionNotifier submitAmprah guard', () {
    test('returns false with expected message when user lacks canAjukanAmprah', () async {
      const userWithoutScope = UserModel(
        id: 5,
        name: 'User Non Scope',
        email: 'nonscope@simlogrs.local',
        roles: ['super_admin'],
        permissions: [],
        unit: null,
        gudang: null,
      );

      final fakeRepo = FakeDistribusiRepository();
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => MockAuthNotifier(userWithoutScope)),
          distribusiRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(amprahActionProvider.notifier);
      final ok = await notifier.submitAmprah(
        urgensi: 'REGULER',
        items: const [],
      );

      expect(ok, isFalse);
      expect(container.read(amprahActionProvider).errorMessage, 'Akun Anda belum terhubung dengan unit ruangan atau gudang');
      expect(fakeRepo.submitCalled, isFalse);
    });
  });
}
