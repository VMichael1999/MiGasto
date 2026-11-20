import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Configuración de Firebase del proyecto `migasto-99dd5`.
/// Son identificadores públicos de la app (no secretos): la protección está en
/// las reglas y en las restricciones de la clave desde la consola de Firebase.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('MiGasto solo corre en iPhone y Android.');
    }
  }

  static const android = FirebaseOptions(
    apiKey: 'AIzaSy-REDACTED',
    appId: '1:000000000000:android:e622a66fb2af7fd2e831f1',
    messagingSenderId: '000000000000',
    projectId: 'migasto-99dd5',
    storageBucket: 'migasto-99dd5.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSy-REDACTED',
    appId: '1:000000000000:ios:2a199125c74c79f5e831f1',
    messagingSenderId: '000000000000',
    projectId: 'migasto-99dd5',
    storageBucket: 'migasto-99dd5.firebasestorage.app',
    iosClientId: '000000000000-c9u4vs72al3n4ofn4mvlda1o1io1lp3t.apps.googleusercontent.com',
    iosBundleId: 'com.migasto.co',
  );
}
