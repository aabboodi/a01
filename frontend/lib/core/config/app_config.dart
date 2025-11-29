import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static String get apiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else if (Platform.isAndroid) {
      // 10.0.2.2 is the special IP for Android Emulator to access host localhost
      // For real devices, you should change this to your machine's LAN IP
      return 'http://10.0.2.2:3000'; 
    } else if (Platform.isIOS) {
      return 'http://localhost:3000';
    }
    return 'http://localhost:3000';
  }

  static String get socketUrl {
    // Socket.io usually connects to the same host but might need ws:// protocol or just the base url
    return apiBaseUrl;
  }
}
