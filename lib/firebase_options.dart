import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Generated for project: genai-x-asc-timetable
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCiW_49-r1CaHPrisOmfEKsdMJRQpVx7U4',
    appId: '1:555294162684:web:a2968648035ca50e0b2179',
    messagingSenderId: '555294162684',
    projectId: 'genai-x-asc-timetable',
    authDomain: 'genai-x-asc-timetable.firebaseapp.com',
    storageBucket: 'genai-x-asc-timetable.firebasestorage.app',
    measurementId: 'G-K43L80HKBQ',
  );
}
