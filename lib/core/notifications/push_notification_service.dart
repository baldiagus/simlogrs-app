import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_payload.dart';

/// Provider Riverpod untuk instans tunggal [PushNotificationService].
final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService.instance;
});

/// Status kesiapan push notification FCM pada perangkat ini.
enum FcmStatus {
  /// Layanan belum dijalankan.
  belumDiinisialisasi,

  /// Firebase tidak tersedia (web atau konfigurasi belum ada).
  tidakTersedia,

  /// Pengguna menolak izin notifikasi.
  izinDitolak,

  /// Firebase siap tetapi token belum terdaftar di backend.
  tokenBelumTerdaftar,

  /// Token terdaftar di backend; notifikasi push aktif.
  aktif,
}

/// Penangan pesan FCM tingkat teratas ketika aplikasi berada di latar belakang atau dihentikan.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Fallback inisialisasi Firebase background: $e');
  }
}

/// Notifier sekaligus penyedia event untuk payload notifikasi yang dibuka oleh pengguna.
class NotificationTapNotifier extends ValueNotifier<NotificationPayload?> {
  final StreamController<NotificationPayload?> _controller =
      StreamController<NotificationPayload?>.broadcast();

  /// Membuat instans notifier dengan nilai awal [value].
  NotificationTapNotifier(super.value);
  /// Mengatur payload notifikasi baru dan meneruskannya ke aliran stream.
  @override
  set value(NotificationPayload? newValue) {
    super.value = newValue;
    _controller.add(newValue);
  }

  /// Mendengarkan perubahan notifikasi sebagai [StreamSubscription].
  StreamSubscription<NotificationPayload?> listen(
    void Function(NotificationPayload? event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  /// Menghasilkan [Stream] dari event notifikasi yang diterima.
  Stream<NotificationPayload?> get stream => _controller.stream;

  /// Mengambil payload tersimpan lalu mengosongkannya tanpa memancarkan event stream.
  /// Mengembalikan null bila tidak ada payload tertunda.
  NotificationPayload? consume() {
    final tersimpan = value;
    if (tersimpan != null) super.value = null;
    return tersimpan;
  }

  /// Menutup controller stream dan membersihkan resource notifier.
  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }
}

/// Layanan terkelola untuk menangani penerimaan dan navigasi push notification SIMLOG RS.
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();

  /// Mengembalikan instans tunggal (singleton) [PushNotificationService].
  factory PushNotificationService() => _instance;

  /// Konstruktor privat untuk inisialisasi internal singleton [PushNotificationService].
  PushNotificationService._internal({
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  /// Mengembalikan referensi instans singleton [PushNotificationService].
  static PushNotificationService get instance => _instance;

  /// ID saluran Android untuk notifikasi persetujuan logistik.
  static const String channelId = 'simlog_approval_channel';

  /// Nama saluran Android untuk notifikasi persetujuan logistik.
  static const String channelName = 'Persetujuan Logistik RS';

  /// Deskripsi saluran Android untuk notifikasi persetujuan logistik.
  static const String channelDescription =
      'Saluran notifikasi persetujuan logistik dan tiket SIMLOG RS';

  /// Konfigurasi saluran Android untuk notifikasi approval dengan prioritas tinggi.
  static const AndroidNotificationChannel approvalChannel =
      AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDescription,
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _localNotifications;
  bool _isFirebaseInitialized = false;

  /// Notifier payload notifikasi yang ditekan pengguna untuk respons UI/navigasi.
  /// Nilai terakhir disimpan sampai dikonsumsi lewat [NotificationTapNotifier.consume].
  final NotificationTapNotifier onNotificationTapped =
      NotificationTapNotifier(null);

  /// Status kesiapan FCM perangkat untuk ditampilkan di UI.
  final ValueNotifier<FcmStatus> fcmStatus =
      ValueNotifier<FcmStatus>(FcmStatus.belumDiinisialisasi);

  /// Callback yang dipanggil setelah pesan FCM foreground ditampilkan; dipasang oleh shell.
  void Function(NotificationPayload payload)? onForegroundMessage;

  /// Stream payload notifikasi yang ditekan pengguna untuk pemantauan reaktif.
  Stream<NotificationPayload?> get onNotificationTappedStream =>
      onNotificationTapped.stream;

  /// Handler statis top-level untuk pendelegasian background message FCM.
  @pragma('vm:entry-point')
  static Future<void> backgroundHandler(RemoteMessage message) async {
    await firebaseMessagingBackgroundHandler(message);
  }

  /// Melakukan inisialisasi Firebase, notifikasi lokal, dan listener pesan masuk.
  /// Izin notifikasi TIDAK diminta di sini; diminta setelah login lewat [requestPermission].
  Future<void> initialize() async {
    if (kIsWeb) {
      fcmStatus.value = FcmStatus.tidakTersedia;
      return;
    }

    try {
      await Firebase.initializeApp();
      _isFirebaseInitialized = true;
      fcmStatus.value = FcmStatus.tokenBelumTerdaftar;
    } catch (e) {
      // Fallback anggun bila Firebase project belum dibuat / kredensial dummy
      debugPrint('Fallback inisialisasi Firebase dilewati: $e');
      fcmStatus.value = FcmStatus.tidakTersedia;
      return;
    }

    // Setup AndroidNotificationChannel ('simlog_approval_channel', 'Persetujuan Logistik RS', importance: Importance.high)
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(approvalChannel);

    // Inisialisasi FlutterLocalNotificationsPlugin
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payloadStr = response.payload;
        if (payloadStr != null && payloadStr.isNotEmpty) {
          try {
            final payload = NotificationPayload.fromJson(payloadStr);
            _emitNotificationTapped(payload);
          } catch (e) {
            debugPrint('Gagal mengurai payload notifikasi lokal: $e');
          }
        }
      },
    );

    // Background handler static top-level
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Tangani onMessage (foreground): parse NotificationPayload, tampilkan pop-up notifikasi lokal sistem via FlutterLocalNotificationsPlugin
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // Tangani interaksi saat notifikasi dibuka dari status background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final payload = parseRemoteMessage(message);
      _emitNotificationTapped(payload);
    });

    // Periksa apakah aplikasi dibuka dari terminasi oleh pesan Firebase
    try {
      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        final payload = parseRemoteMessage(initialMessage);
        _emitNotificationTapped(payload);
      }
    } catch (e) {
      debugPrint('Gagal membaca initial FCM message: $e');
    }
  }

  /// Meminta izin notifikasi Android 13+ dan iOS, lalu memperbarui [fcmStatus].
  /// Mengembalikan true bila izin diberikan, false bila ditolak atau Firebase tidak tersedia.
  Future<bool?> requestPermission() async {
    if (kIsWeb || !_isFirebaseInitialized) {
      fcmStatus.value = FcmStatus.tidakTersedia;
      return false;
    }
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final izinLokal = await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      final diizinkan =
          (settings.authorizationStatus == AuthorizationStatus.authorized ||
                  settings.authorizationStatus ==
                      AuthorizationStatus.provisional) &&
              izinLokal != false;
      if (!diizinkan) {
        fcmStatus.value = FcmStatus.izinDitolak;
      } else if (fcmStatus.value == FcmStatus.izinDitolak) {
        fcmStatus.value = FcmStatus.tokenBelumTerdaftar;
      }
      return diizinkan;
    } catch (e) {
      debugPrint('Gagal meminta izin notifikasi: $e');
      return false;
    }
  }

  /// Memperbarui [fcmStatus] sesuai hasil sinkronisasi token ke backend.
  /// Diabaikan bila FCM tidak tersedia atau izin ditolak agar status tidak menyesatkan.
  void updateTokenSyncResult(bool berhasil) {
    final saatIni = fcmStatus.value;
    if (saatIni != FcmStatus.tokenBelumTerdaftar &&
        saatIni != FcmStatus.aktif) {
      return;
    }
    fcmStatus.value =
        berhasil ? FcmStatus.aktif : FcmStatus.tokenBelumTerdaftar;
  }

  /// Aliran token FCM baru dari Firebase, atau null bila Firebase belum siap.
  Stream<String>? get tokenRefreshStream {
    if (kIsWeb || !_isFirebaseInitialized) return null;
    return FirebaseMessaging.instance.onTokenRefresh;
  }

  /// Mengambil token pendaftaran FCM perangkat dalam blok try-catch.
  Future<String?> getToken() async {
    if (kIsWeb) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      debugPrint('Gagal mengambil token FCM: $e');
      return null;
    }
  }

  /// Mengurai objek [RemoteMessage] dari FCM menjadi instans [NotificationPayload].
  NotificationPayload parseRemoteMessage(RemoteMessage message) {
    final map = Map<String, dynamic>.from(message.data);
    final notificationTitle = message.notification?.title;
    final notificationBody = message.notification?.body;

    if ((map['judul'] == null || map['judul'].toString().isEmpty) &&
        (map['title'] == null || map['title'].toString().isEmpty) &&
        notificationTitle != null) {
      map['judul'] = notificationTitle;
    }
    if ((map['pesan'] == null || map['pesan'].toString().isEmpty) &&
        (map['body'] == null || map['body'].toString().isEmpty) &&
        (map['message'] == null || map['message'].toString().isEmpty) &&
        notificationBody != null) {
      map['pesan'] = notificationBody;
    }
    return NotificationPayload.fromMap(map);
  }

  /// Menampilkan pop-up notifikasi lokal sistem berdasarkan [NotificationPayload].
  Future<void> showLocalNotification(NotificationPayload payload) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _localNotifications.show(
      id: id,
      title: payload.judul.isNotEmpty ? payload.judul : 'SIMLOG RS',
      body: payload.pesan.isNotEmpty ? payload.pesan : null,
      notificationDetails: notificationDetails,
      payload: payload.toJson(),
    );
  }

  /// Menangani pesan FCM yang masuk saat aplikasi berjalan di latar depan (foreground).
  /// Menampilkan notifikasi lokal lalu memanggil [onForegroundMessage] agar data layar disegarkan.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final payload = parseRemoteMessage(message);
    await showLocalNotification(payload);
    try {
      onForegroundMessage?.call(payload);
    } catch (e) {
      debugPrint('Callback pesan foreground gagal: $e');
    }
  }

  /// Meneruskan payload notifikasi yang dibuka ke notifier dan stream.
  void _emitNotificationTapped(NotificationPayload payload) {
    onNotificationTapped.value = payload;
  }
}
