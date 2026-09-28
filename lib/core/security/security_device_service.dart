import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

final securityDeviceServiceProvider = Provider<SecurityDeviceService>((ref) {
  return SecurityDeviceService();
});

final isDeviceRootedProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(securityDeviceServiceProvider);
  return await service.isDeviceRooted();
});
