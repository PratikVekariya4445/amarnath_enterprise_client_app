import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Project ID: `whats-deleted-8ca7b`
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCcCL5N2ns_9d8TVhbSnyVCszXXVJ3AiFQ',
    appId: '1:690647262004:android:dc684524168cdeaf3a3b61',
    messagingSenderId: '690647262004',
    projectId: 'whats-deleted-8ca7b',
    databaseURL: 'https://whats-deleted-8ca7b.firebaseio.com',
    storageBucket: 'whats-deleted-8ca7b.appspot.com',
  );
}
