import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAyhGKcUAZ4zgh8ZJR28vYKQKZ0rpfRTD0',
    authDomain: 'streamhub-855ab.firebaseapp.com',
    databaseURL: 'https://streamhub-855ab-default-rtdb.firebaseio.com/',
    projectId: 'streamhub-855ab',
    storageBucket: 'streamhub-855ab.firebasestorage.app',
    messagingSenderId: '630487046265',
    appId: '1:630487046265:web:5f7ef5fcc4dcf37ea91ca8',
    measurementId: 'G-8YHKTEZMYP',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyANxguwpZdOi_Y6eV6IdS4SgEfZ4p9E0s8',
    authDomain: 'streamhub-855ab.firebaseapp.com',
    databaseURL: 'https://streamhub-855ab-default-rtdb.firebaseio.com/',
    projectId: 'streamhub-855ab',
    storageBucket: 'streamhub-855ab.firebasestorage.app',
    messagingSenderId: '630487046265',
    appId: '1:630487046265:android:76d9b1d346f37fd8a91ca8',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA8k3cfczN-XTeCZ91AKRrXaJoCyB9wuZY',
    authDomain: 'streamhub-855ab.firebaseapp.com',
    databaseURL: 'https://streamhub-855ab-default-rtdb.firebaseio.com/',
    projectId: 'streamhub-855ab',
    storageBucket: 'streamhub-855ab.firebasestorage.app',
    messagingSenderId: '630487046265',
    appId: '1:630487046265:ios:d02e7b61839a5403a91ca8',
    iosBundleId: 'zyrion.app',
  );
}
