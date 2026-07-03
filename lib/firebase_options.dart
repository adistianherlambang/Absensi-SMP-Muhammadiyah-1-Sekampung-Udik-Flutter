import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Return dummy options that allow compiling. 
    // The user can run "flutterfire configure" to overwrite these options with their live project keys.
    return const FirebaseOptions(
      apiKey: 'mock-api-key-smp-muhammadiyah-1',
      appId: '1:1234567890:android:mockappiddummy',
      messagingSenderId: '1234567890',
      projectId: 'smp-muh-1-presensi',
      databaseURL: 'https://smp-muh-1-presensi-default-rtdb.firebaseio.com',
      storageBucket: 'smp-muh-1-presensi.appspot.com',
    );
  }
}
