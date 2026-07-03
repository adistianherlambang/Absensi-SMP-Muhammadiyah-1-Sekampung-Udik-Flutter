// File generated manually based on google-services.json and GoogleService-Info.plist.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBXn5rzzjd6ST5Ia229vafGi7SzBjaEKO8',
    appId: '1:117767145737:android:7f2461a65cb3d5d16d2bd8',
    messagingSenderId: '117767145737',
    projectId: 'absensi-smp-muhi-flutter',
    databaseURL:
        'https://absensi-smp-muhi-flutter-default-rtdb.asia-southeast1.firebasedatabase.app/',
    storageBucket: 'absensi-smp-muhi-flutter.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD8--VlLUcesF3v4Tgtn7o7SZEITw86oqQ',
    appId: '1:117767145737:ios:0eecc3785154b95d6d2bd8',
    messagingSenderId: '117767145737',
    projectId: 'absensi-smp-muhi-flutter',
    databaseURL:
        'https://absensi-smp-muhi-flutter-default-rtdb.asia-southeast1.firebasedatabase.app/',
    storageBucket: 'absensi-smp-muhi-flutter.firebasestorage.app',
    iosBundleId: 'com.example.flutterApplication1',
  );
}
