import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:simlog_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:simlog_mobile/features/profile/presentation/screens/ubah_password_screen.dart';
import 'package:simlog_mobile/shared/widgets/custom_button.dart';

/// Mock notifier autentikasi untuk pengujian ubah kata sandi.
class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  /// Menginisialisasi mock notifier autentikasi dengan state unauthenticated.
  MockAuthNotifier() : super(AuthState.unauthenticated());

  /// Menandai apakah metode gantiPasswordWajib telah dipanggil.
  bool gantiPasswordWajibCalled = false;

  /// Menyimpan kata sandi saat ini yang dikirim pada pemanggilan terakhir.
  String? lastPasswordSaatIni;

  /// Menyimpan kata sandi baru yang dikirim pada pemanggilan terakhir.
  String? lastPasswordBaru;

  /// Menyimpan konfirmasi kata sandi baru yang dikirim pada pemanggilan terakhir.
  String? lastPasswordBaruConfirmation;

  /// Menentukan apakah pemanggilan gantiPasswordWajib harus melempar exception.
  bool shouldThrow = false;

  /// Pesan error yang dilempar bila shouldThrow bernilai true.
  String errorMessage = 'Kata sandi saat ini tidak sesuai.';

  /// Menyimulasikan pemanggilan gantiPasswordWajib untuk pengujian UI.
  @override
  Future<void> gantiPasswordWajib({
    required String passwordSaatIni,
    required String passwordBaru,
    required String passwordBaruConfirmation,
  }) async {
    gantiPasswordWajibCalled = true;
    lastPasswordSaatIni = passwordSaatIni;
    lastPasswordBaru = passwordBaru;
    lastPasswordBaruConfirmation = passwordBaruConfirmation;
    if (shouldThrow) {
      throw Exception(errorMessage);
    }
  }

  /// Menangani pemanggilan metode yang tidak di-override secara eksplisit.
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Helper untuk merender UbahPasswordScreen dengan konfigurasi ProviderScope dan navigasi.
Widget _buildTestWidget({
  required MockAuthNotifier mockAuthNotifier,
  bool pushFromHome = false,
}) {
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith((ref) => mockAuthNotifier),
    ],
    child: MaterialApp(
      home: pushFromHome
          ? Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UbahPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text('Buka Ubah Password'),
                ),
              ),
            )
          : const UbahPasswordScreen(),
    ),
  );
}

/// Rangkaian pengujian widget untuk layar UbahPasswordScreen.
void main() {
  late MockAuthNotifier mockAuth;

  setUp(() {
    mockAuth = MockAuthNotifier();
  });

  testWidgets(
      'Merender 3 input field, tombol simpan, banner info, dan indikator syarat kata sandi',
      (tester) async {
    await tester.pumpWidget(_buildTestWidget(mockAuthNotifier: mockAuth));
    await tester.pumpAndSettle();

    // Pastikan AppBar dan Banner tampil
    expect(find.text('Ubah Kata Sandi'), findsOneWidget);
    expect(
      find.text(
        'Kata sandi baru akan berlaku untuk login di SIMLOG RS Web Portal dan Aplikasi Mobile.',
      ),
      findsOneWidget,
    );

    // Pastikan 3 input field tampil
    expect(find.text('Kata Sandi Saat Ini'), findsOneWidget);
    expect(find.text('Kata Sandi Baru'), findsOneWidget);
    expect(find.text('Konfirmasi Kata Sandi Baru'), findsOneWidget);

    // Pastikan tombol simpan tampil
    expect(find.widgetWithText(CustomButton, 'Simpan Kata Sandi Baru'), findsOneWidget);

    // Pastikan indikator syarat kata sandi tampil
    expect(find.text('Syarat Kata Sandi:'), findsOneWidget);
    expect(find.text('Minimal 8 karakter'), findsOneWidget);
    expect(find.text('Kombinasi huruf dan angka'), findsOneWidget);
    expect(find.text('Konfirmasi cocok'), findsOneWidget);
  });

  testWidgets('Menampilkan pesan validasi ketika form dikirim dalam keadaan kosong',
      (tester) async {
    await tester.pumpWidget(_buildTestWidget(mockAuthNotifier: mockAuth));
    await tester.pumpAndSettle();

    // Tekan tombol simpan saat form masih kosong
    final buttonFinder = find.widgetWithText(CustomButton, 'Simpan Kata Sandi Baru');
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    // Pesan error validasi harus muncul
    expect(find.text('Kata sandi saat ini wajib diisi'), findsOneWidget);
    expect(find.text('Kata sandi baru wajib diisi'), findsOneWidget);
    expect(find.text('Konfirmasi kata sandi baru wajib diisi'), findsOneWidget);
    expect(mockAuth.gantiPasswordWajibCalled, isFalse);
  });

  testWidgets(
      'Menampilkan pesan validasi ketika kata sandi kurang dari 8 karakter atau bukan kombinasi huruf dan angka',
      (tester) async {
    await tester.pumpWidget(_buildTestWidget(mockAuthNotifier: mockAuth));
    await tester.pumpAndSettle();

    // Masukkan kata sandi saat ini
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kata Sandi Saat Ini'),
      'passwordLama123',
    );

    // Masukkan kata sandi baru < 8 karakter
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kata Sandi Baru'),
      'abc1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Konfirmasi Kata Sandi Baru'),
      'abc1',
    );

    final buttonFinder = find.widgetWithText(CustomButton, 'Simpan Kata Sandi Baru');
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Kata sandi minimal 8 karakter'), findsOneWidget);

    // Masukkan kata sandi baru >= 8 karakter namun hanya huruf
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kata Sandi Baru'),
      'hanyahurufsaja',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Konfirmasi Kata Sandi Baru'),
      'hanyahurufsaja',
    );

    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Kombinasi huruf dan angka wajib dipenuhi'), findsOneWidget);
  });

  testWidgets('Menampilkan pesan validasi ketika konfirmasi kata sandi tidak cocok',
      (tester) async {
    await tester.pumpWidget(_buildTestWidget(mockAuthNotifier: mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kata Sandi Saat Ini'),
      'passwordLama123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kata Sandi Baru'),
      'passwordBaru123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Konfirmasi Kata Sandi Baru'),
      'passwordBeda999',
    );

    final buttonFinder = find.widgetWithText(CustomButton, 'Simpan Kata Sandi Baru');
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Konfirmasi kata sandi tidak cocok'), findsOneWidget);
    expect(mockAuth.gantiPasswordWajibCalled, isFalse);
  });

  testWidgets(
      'Indikator syarat kata sandi realtime menampilkan centang hijau saat syarat terpenuhi',
      (tester) async {
    await tester.pumpWidget(_buildTestWidget(mockAuthNotifier: mockAuth));
    await tester.pumpAndSettle();

    // Awalnya belum ada syarat yang terpenuhi
    expect(find.byIcon(LucideIcons.checkCircle2), findsNothing);

    // Isi kata sandi baru yang valid: >= 8 karakter & kombinasi huruf + angka
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kata Sandi Baru'),
      'PassBaru123',
    );
    await tester.pumpAndSettle();

    // Dua butir (panjang >= 8 dan alfanumerik) terpenuhi
    expect(find.byIcon(LucideIcons.checkCircle2), findsNWidgets(2));

    // Isi konfirmasi yang cocok
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Konfirmasi Kata Sandi Baru'),
      'PassBaru123',
    );
    await tester.pumpAndSettle();

    // Seluruh tiga butir terpenuhi
    expect(find.byIcon(LucideIcons.checkCircle2), findsNWidgets(3));
  });

  testWidgets(
      'Memanggil gantiPasswordWajib, menampilkan toast sukses, dan menutup halaman saat berhasil',
      (tester) async {
    await tester.pumpWidget(_buildTestWidget(
      mockAuthNotifier: mockAuth,
      pushFromHome: true,
    ));
    await tester.pumpAndSettle();

    // Buka UbahPasswordScreen dari halaman awal
    await tester.tap(find.text('Buka Ubah Password'));
    await tester.pumpAndSettle();

    expect(find.text('Kata Sandi Saat Ini'), findsOneWidget);

    // Isi semua field dengan data valid
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kata Sandi Saat Ini'),
      'passwordLama123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kata Sandi Baru'),
      'passwordBaru123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Konfirmasi Kata Sandi Baru'),
      'passwordBaru123',
    );

    // Submit form
    final buttonFinder = find.widgetWithText(CustomButton, 'Simpan Kata Sandi Baru');
    await tester.tap(buttonFinder);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Pastikan API terpanggil dengan parameter yang sesuai
    expect(mockAuth.gantiPasswordWajibCalled, isTrue);
    expect(mockAuth.lastPasswordSaatIni, 'passwordLama123');
    expect(mockAuth.lastPasswordBaru, 'passwordBaru123');
    expect(mockAuth.lastPasswordBaruConfirmation, 'passwordBaru123');

    // Pastikan toast sukses tampil
    expect(find.text('Kata sandi berhasil diperbarui.'), findsOneWidget);

    // Selesaikan animasi pop navigator dan habiskan durasi toast
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Layar telah ditutup dan kembali ke tombol pembuka
    expect(find.text('Buka Ubah Password'), findsOneWidget);
    expect(find.byType(UbahPasswordScreen), findsNothing);
  });

  testWidgets('Menampilkan toast error saat pemanggilan gantiPasswordWajib gagal',
      (tester) async {
    mockAuth.shouldThrow = true;
    mockAuth.errorMessage = 'Kata sandi saat ini tidak sesuai.';

    await tester.pumpWidget(_buildTestWidget(mockAuthNotifier: mockAuth));
    await tester.pumpAndSettle();

    // Isi semua field dengan data valid
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kata Sandi Saat Ini'),
      'passwordSalah123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kata Sandi Baru'),
      'passwordBaru123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Konfirmasi Kata Sandi Baru'),
      'passwordBaru123',
    );

    // Submit form
    final buttonFinder = find.widgetWithText(CustomButton, 'Simpan Kata Sandi Baru');
    await tester.tap(buttonFinder);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // Toast error harus muncul dengan pesan dari backend
    expect(find.text('Kata sandi saat ini tidak sesuai.'), findsOneWidget);
    expect(mockAuth.gantiPasswordWajibCalled, isTrue);

    // Habiskan durasi toast agar tidak ada timer yang tertinggal
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}
