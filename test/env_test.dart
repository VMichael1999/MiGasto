import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_gasto/core/config/env.dart';
import 'package:mi_gasto/firebase_options.dart';

void main() {
  tearDown(() {
    Env.setForTest(const {});
    debugDefaultTargetPlatformOverride = null;
  });

  test('lee CLAVE=valor, ignora comentarios, líneas vacías y comillas', () {
    final m = Env.parse('''
# comentario
A=1

B = "dos"
C='tres'
D=con=igual
SIN_VALOR
''');
    expect(m, {'A': '1', 'B': 'dos', 'C': 'tres', 'D': 'con=igual'});
  });

  test('sin claves de Firebase no hay configuración y la app sigue como invitado', () {
    Env.setForTest(const {});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(DefaultFirebaseOptions.currentPlatform, isNull);
  });

  test('con las claves en el .env arma la configuración de cada plataforma', () {
    Env.setForTest(const {
      'FIREBASE_PROJECT_ID': 'proyecto',
      'FIREBASE_MESSAGING_SENDER_ID': '123',
      'FIREBASE_ANDROID_API_KEY': 'key-a',
      'FIREBASE_ANDROID_APP_ID': 'app-a',
      'FIREBASE_IOS_API_KEY': 'key-i',
      'FIREBASE_IOS_APP_ID': 'app-i',
      'GOOGLE_IOS_CLIENT_ID': 'cli-i',
    });
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(DefaultFirebaseOptions.currentPlatform?.apiKey, 'key-a');
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final ios = DefaultFirebaseOptions.currentPlatform;
    expect(ios?.appId, 'app-i');
    expect(ios?.iosClientId, 'cli-i');
  });

  test('la clave de Google Maps sale del .env empaquetado cuando no hay dart-define', () {
    Env.setForTest(const {});
    expect(Env.hasMapsKey, isFalse);
    Env.setForTest(const {'GOOGLE_MAPS_API_KEY': 'clave-de-prueba'});
    expect(Env.hasMapsKey, isTrue);
    expect(Env.googleMapsApiKey, 'clave-de-prueba');
  });
}
