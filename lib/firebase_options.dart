import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'core/config/env.dart';

/// Configuración de Firebase tomada del `.env` (ver `.env.example`).
/// Si faltan los valores devuelve `null` y la app funciona solo como invitado.
class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return _build(
          apiKey: Env.value('FIREBASE_IOS_API_KEY'),
          appId: Env.value('FIREBASE_IOS_APP_ID'),
          iosClientId: Env.value('GOOGLE_IOS_CLIENT_ID'),
          iosBundleId: Env.value('FIREBASE_IOS_BUNDLE_ID'),
        );
      case TargetPlatform.android:
        return _build(
          apiKey: Env.value('FIREBASE_ANDROID_API_KEY'),
          appId: Env.value('FIREBASE_ANDROID_APP_ID'),
        );
      default:
        return null;
    }
  }

  static FirebaseOptions? _build({
    required String apiKey,
    required String appId,
    String iosClientId = '',
    String iosBundleId = '',
  }) {
    final sender = Env.value('FIREBASE_MESSAGING_SENDER_ID');
    final project = Env.value('FIREBASE_PROJECT_ID');
    if (apiKey.isEmpty || appId.isEmpty || sender.isEmpty || project.isEmpty) return null;
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: sender,
      projectId: project,
      storageBucket: Env.value('FIREBASE_STORAGE_BUCKET').isEmpty
          ? null
          : Env.value('FIREBASE_STORAGE_BUCKET'),
      iosClientId: iosClientId.isEmpty ? null : iosClientId,
      iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
    );
  }
}
