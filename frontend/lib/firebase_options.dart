// Placeholder Firebase options. Замените реальными значениями из Firebase Console
// (flutterfire configure) для продакшна. Dummy-значения позволяют сборке/анализу
// пройти без реального Firebase-проекта; в dev-режиме (FCM_DEV_MODE=true) реальные
// вызовы FCM не выполняются.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return _web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      default:
        return _android;
    }
  }

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'AIzaSyCP4wLbN9XYNwTq1CZ3YbW1A_8KdZNc_Wg',
    appId: '1:325854827017:android:0795f7affd62ff27171ed8',
    messagingSenderId: '325854827017',
    projectId: 'aifb-3326b',
    storageBucket: 'aifb-3326b.firebasestorage.app',
  );

  static const FirebaseOptions _ios = FirebaseOptions(
    apiKey: 'AIzaSyDUMMY-ios-placeholder-key',
    appId: '1:000000000000:ios:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'aifb-dev-placeholder',
    storageBucket: 'aifb-dev-placeholder.appspot.com',
    iosBundleId: 'com.aifb.app',
  );

  static const FirebaseOptions _web = FirebaseOptions(
    apiKey: 'AIzaSyDUMMY-web-placeholder-key',
    appId: '1:000000000000:web:0000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'aifb-dev-placeholder',
    authDomain: 'aifb-dev-placeholder.firebaseapp.com',
    storageBucket: 'aifb-dev-placeholder.appspot.com',
  );
}
