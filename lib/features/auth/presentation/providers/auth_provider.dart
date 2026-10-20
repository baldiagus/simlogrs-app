import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simlog_mobile/core/notifications/fcm_token_repository.dart'
    hide fcmTokenRepositoryProvider;
import 'package:simlog_mobile/core/notifications/push_notification_service.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../pengadaan/presentation/providers/approval_provider.dart';
import '../../../audit/presentation/providers/audit_provider.dart';
import '../../../anggaran/presentation/providers/anggaran_provider.dart';
import '../../../aset/presentation/providers/peminjaman_provider.dart';
import '../../../aset/presentation/providers/pengalihan_provider.dart';
import '../../../gudang/presentation/providers/gudang_provider.dart';
import '../../../gudang/presentation/providers/inbound_provider.dart';
import '../../../pengadaan/presentation/providers/pengadaan_provider.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  /// State awal sebelum sesi diperiksa.
  factory AuthState.initial() => const AuthState(status: AuthStatus.initial);
  /// State saat proses otentikasi berlangsung.
  factory AuthState.loading() => const AuthState(status: AuthStatus.loading);
  /// State sukses login dengan data user.
  factory AuthState.authenticated(UserModel user) =>
      AuthState(status: AuthStatus.authenticated, user: user);
  /// State belum login atau sesi berakhir, dengan pesan error opsional untuk ditampilkan.
  factory AuthState.unauthenticated([String? message]) =>
      AuthState(status: AuthStatus.unauthenticated, errorMessage: message);

  /// True jika status authenticated dan data user tersedia.
  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;
  StreamSubscription<String>? _tokenRefreshSub;

  /// Mendaftarkan handler 401 ke DioClient lalu langsung memeriksa sesi tersimpan.
  AuthNotifier(this._repository, DioClient dioClient, this._ref) : super(AuthState.initial()) {
    dioClient.onUnauthorized = handleUnauthorized;
    checkAuth();
  }

  /// Memeriksa token dan cache saat startup; tampilkan user cache dulu, lalu segarkan dari server.
  Future<void> checkAuth() async {
    state = AuthState.loading();
    try {
      final hasToken = await _repository.hasValidToken();
      if (!hasToken) {
        state = AuthState.unauthenticated();
        return;
      }

      final cachedUser = await _repository.getCachedUser();
      if (cachedUser != null) {
        state = AuthState.authenticated(cachedUser);
      }

      final user = await _repository.getMe();
      state = AuthState.authenticated(user);
      _syncFcmTokenInBackground();
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  /// Login dengan email dan password; hasilnya (user atau pesan error) disimpan di state.
  Future<void> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    state = AuthState.loading();
    try {
      final user = await _repository.login(
        email: email,
        password: password,
        deviceName: deviceName,
      );
      _clearUserCaches();
      state = AuthState.authenticated(user);
      _syncFcmTokenInBackground();
    } on ApiException catch (e) {
      state = AuthState.unauthenticated(e.message);
    } catch (e) {
      state = AuthState.unauthenticated(e.toString());
    }
  }
  /// Mengganti password wajib; error dilempar ke pemanggil agar UI bisa menampilkannya.
  Future<void> gantiPasswordWajib({
    required String passwordSaatIni,
    required String passwordBaru,
    required String passwordBaruConfirmation,
  }) async {
    final updatedUser = await _repository.gantiPasswordWajib(
      passwordSaatIni: passwordSaatIni,
      passwordBaru: passwordBaru,
      passwordBaruConfirmation: passwordBaruConfirmation,
    );
    state = AuthState.authenticated(updatedUser);
  }

  /// Menghapus pesan error dari state tanpa mengubah status dan user.
  void clearError() {
    if (state.errorMessage != null) {
      state = AuthState(
        status: state.status,
        user: state.user,
        errorMessage: null,
      );
    }
  }


  /// Logout: ubah state ke unauthenticated, hapus sesi lokal, dan reset cache data user.
  Future<void> logout() async {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _clearUserCaches();
    state = AuthState.unauthenticated();
    try {
      await _ref.read(fcmTokenRepositoryProvider).deleteToken();
    } catch (_) {
      // Abaikan error saat menghapus token FCM di backend
    }
    await _repository.logout();
  }

  /// Meminta izin notifikasi, mengambil token FCM, menyinkronkannya ke backend, lalu memantau refresh token.
  /// Berjalan di latar belakang; hasil sinkron dicatat ke [PushNotificationService.fcmStatus].
  void _syncFcmTokenInBackground() {
    unawaited(() async {
      try {
        final service = PushNotificationService.instance;
        await service.requestPermission();
        final token = await service.getToken();
        if (token != null && token.isNotEmpty) {
          await _kirimToken(token);
        }
        _pasangTokenRefresh();
      } catch (_) {
        // Jangan biarkan kegagalan FCM memblokir login
      }
    }());
  }

  /// Mengirim [token] ke backend dan menyimpan hasilnya ke status FCM layanan push.
  Future<void> _kirimToken(String token) async {
    final berhasil = await _ref.read(fcmTokenRepositoryProvider).syncToken(token);
    PushNotificationService.instance.updateTokenSyncResult(berhasil);
  }

  /// Memasang listener onTokenRefresh agar token baru dikirim ulang selama pengguna masih login.
  void _pasangTokenRefresh() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = PushNotificationService.instance.tokenRefreshStream?.listen(
      (token) {
        if (state.isAuthenticated && token.isNotEmpty) {
          unawaited(_kirimToken(token));
        }
      },
      onError: (Object _) {},
    );
  }

  /// Dipanggil saat server menolak token (401); bersihkan cache dan arahkan ke login.
  void handleUnauthorized() {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    _clearUserCaches();
    state = AuthState.unauthenticated('Sesi Anda telah berakhir. Silakan login kembali.');
  }

  /// Membatalkan langganan refresh token FCM saat notifier dibuang.
  @override
  void dispose() {
    _tokenRefreshSub?.cancel();
    super.dispose();
  }

  /// Logout otomatis karena tidak aktif demi keamanan perangkat bersama.
  Future<void> handleSessionTimeout() async {
    _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await _repository.logout();
    _clearUserCaches();
    state = AuthState.unauthenticated('Sesi berakhir otomatis demi keamanan gawai bersama (inaktivitas 30 menit).');
  }

  /// Membatalkan cache provider data milik user sebelumnya agar tidak bocor ke user berikutnya.
  void _clearUserCaches() {
    try {
      _ref.invalidate(dashboardSummaryProvider);
      _ref.invalidate(approvalPendingProvider);
      _ref.invalidate(poListProvider);
      _ref.invalidate(registerTemuanProvider);
      _ref.invalidate(auditSummaryProvider);
      _ref.invalidate(screeningAnggaranProvider);
      _ref.invalidate(daftarPeminjamanSayaProvider);
      _ref.invalidate(daftarApprovalPeminjamanProvider);
      _ref.invalidate(daftarPoInboundProvider);
      _ref.invalidate(daftarRakProvider);
      _ref.invalidate(selectedKategoriPengalihanProvider);
      _ref.invalidate(daftarPengalihanProvider);
      _ref.invalidate(countOtorisasiPengalihanProvider);
    } catch (_) {
      // Abaikan jika provider belum pernah diinisialisasi
    }
  }
}

  /// Provider state otentikasi global yang dipakai AuthGate dan seluruh fitur.
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final dioClient = ref.watch(dioClientProvider);
  return AuthNotifier(repository, dioClient, ref);
});

/// Provider repositori sinkronisasi token FCM perangkat ke server.
final fcmTokenRepositoryProvider =
    Provider((ref) => FcmTokenRepository(ref.watch(dioClientProvider)));
