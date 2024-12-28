import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAFyZJv5FLyy7omcKHdKP2Zi96sDa0-Zjg',
    appId: '1:1067444901462:android:63e0f7a7b136f1f3514df7',
    messagingSenderId: '1067444901462',
    projectId: 'magazine-nexus',
    authDomain: 'magazine-nexus.firebaseapp.com',
    storageBucket: 'magazine-nexus.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAFyZJv5FLyy7omcKHdKP2Zi96sDa0-Zjg',
    appId: '1:1067444901462:android:63e0f7a7b136f1f3514df7',
    messagingSenderId: '1067444901462',
    projectId: 'magazine-nexus',
    storageBucket: 'magazine-nexus.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '1067444901462',
    projectId: 'magazine-nexus',
    storageBucket: 'magazine-nexus.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.example.magazineNexus',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: '1067444901462',
    projectId: 'magazine-nexus',
    storageBucket: 'magazine-nexus.firebasestorage.app',
    iosClientId: 'YOUR_MACOS_CLIENT_ID',
    iosBundleId: 'com.example.magazineNexus',
  );
}
