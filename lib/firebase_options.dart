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
        throw UnsupportedError(
          'Android no está configurado todavía para este proyecto.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS no está configurado todavía para este proyecto.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'macOS no está configurado todavía para este proyecto.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'Windows no está configurado todavía para este proyecto.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Linux no está configurado todavía para este proyecto.',
        );
      default:
        throw UnsupportedError('Plataforma no soportada para este proyecto.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBw4THyt4pJRmUaXtAvkU5L1eUoephq7yw',
    appId: '1:474729885346:web:d61675fd0aa3d8a024f1fb',
    messagingSenderId: '474729885346',
    projectId: 'financeapp2-3fecd',
    authDomain: 'financeapp2-3fecd.firebaseapp.com',
    storageBucket: 'financeapp2-3fecd.firebasestorage.app',
    measurementId: 'G-2DRYV9X93D',
  );
}
