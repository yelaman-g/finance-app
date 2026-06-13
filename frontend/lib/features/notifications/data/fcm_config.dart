import 'package:flutter_dotenv/flutter_dotenv.dart';

class FcmConfig {
  FcmConfig._();

  static bool get devMode {
    final v = dotenv.isInitialized ? dotenv.env['FCM_DEV_MODE'] : null;
    return v == null || v.toLowerCase() != 'false';
  }
}
