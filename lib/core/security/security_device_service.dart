import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Layanan keamanan perangkat: mendeteksi root lewat MethodChannel native Android.
class SecurityDeviceService {
  static const MethodChannel _channel = MethodChannel('com.simlogrs.simlog_mobile/security');

  /// Memeriksa apakah perangkat terdeteksi dalam status root/jailbreak atau memakai build test-keys.
  Future<bool> isDeviceRooted() async {
    if (kIsWeb || !Platform.isAndroid) {
      return false;
    }
    try {
      final isRooted = await _channel.invokeMethod<bool>('isDeviceRooted');
      return isRooted == true;
    } catch (_) {
      return false;
    }
  }
}

/// Provider singleton SecurityDeviceService.
final securityDeviceServiceProvider = Provider<SecurityDeviceService>((ref) {
  return SecurityDeviceService();
});

/// Provider status root perangkat (true bila terdeteksi root); dipakai banner peringatan di layar login.
final isDeviceRootedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(securityDeviceServiceProvider);
  return await service.isDeviceRooted();
});
