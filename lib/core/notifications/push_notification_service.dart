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
  final NotificationTapNotifier onNotificationTapped =
      NotificationTapNotifier(null);

  /// Stream payload notifikasi yang ditekan pengguna untuk pemantauan reaktif.
  Stream<NotificationPayload?> get onNotificationTappedStream =>
      onNotificationTapped.stream;

  /// Handler statis top-level untuk pendelegasian background message FCM.
  @pragma('vm:entry-point')
  static Future<void> backgroundHandler(RemoteMessage message) async {
    await firebaseMessagingBackgroundHandler(message);
  }

  /// Melakukan inisialisasi Firebase, notifikasi lokal, dan listener pesan masuk.
  Future<void> initialize() async {
    if (kIsWeb) return;

    try {
      await Firebase.initializeApp();
      _isFirebaseInitialized = true;
    } catch (e) {
      // Fallback anggun bila Firebase project belum dibuat / kredensial dummy
      debugPrint('Fallback inisialisasi Firebase dilewati: $e');
      return;
    }

    // Request permission notifikasi Android 13+ (POST_NOTIFICATIONS)
    await requestPermission();

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

  /// Meminta izin notifikasi Android 13+ dan iOS.
  Future<bool?> requestPermission() async {
    if (kIsWeb) return false;
    try {
      if (_isFirebaseInitialized) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      return await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Gagal meminta izin notifikasi: $e');
      return false;
    }
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
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final payload = parseRemoteMessage(message);
    await showLocalNotification(payload);
  }

  /// Meneruskan payload notifikasi yang dibuka ke notifier dan stream.
  void _emitNotificationTapped(NotificationPayload payload) {
    onNotificationTapped.value = payload;
  }
}
