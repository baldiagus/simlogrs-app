import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/features/auth/data/models/user_model.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/profile/presentation/screens/profile_screen.dart';
import 'package:simlog_mobile/features/profile/presentation/screens/ubah_password_screen.dart';

/// Mock notifier autentikasi untuk pengujian ProfileScreen.
class MockProfileAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  /// Menginisialisasi mock notifier dengan data pengguna aktif.
  MockProfileAuthNotifier(UserModel user) : super(AuthState.authenticated(user));

  /// Menangani pemanggilan metode tak terdefinisi.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Pengujian widget untuk kartu Keamanan Akun di ProfileScreen.
void main() {
  testWidgets(
      'ProfileScreen menampilkan kartu Keamanan Akun dan membuka UbahPasswordScreen saat diketuk',
      (tester) async {
    const testUser = UserModel(
      id: 10,
      name: 'Dr. Jane Logistik',
      email: 'jane@simlogrs.local',
      roles: ['admin_logistik'],
      permissions: ['baca_aset', 'buat_po'],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => MockProfileAuthNotifier(testUser)),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Pastikan kartu wewenang spatie lama sudah tidak tampil
    expect(find.text('Wewenang Sistem (Spatie RBAC)'), findsNothing);

    // Pastikan kartu Keamanan Akun tampil
    expect(find.text('Keamanan Akun'), findsOneWidget);
    expect(find.text('Ubah Kata Sandi'), findsOneWidget);
    expect(
      find.text('Perbarui kata sandi untuk akses Web & Mobile'),
      findsOneWidget,
    );
    expect(find.byIcon(LucideIcons.keyRound), findsOneWidget);

    // Ketuk item Ubah Kata Sandi
    await tester.tap(find.text('Ubah Kata Sandi'));
    await tester.pumpAndSettle();

    // Pastikan berpindah ke UbahPasswordScreen
    expect(find.byType(UbahPasswordScreen), findsOneWidget);
  });
}
