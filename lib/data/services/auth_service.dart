import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart' as crypto;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/env.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// «Iniciar sesión con Apple» se activa cuando haya cuenta de Apple Developer de pago
/// (capacidad, identificador de servicio y proveedor en Firebase).
const bool kAppleSignInEnabled = false;

/// Datos mínimos de la cuenta con la que entró el usuario.
class AuthAccount {
  const AuthAccount({required this.uid, this.email, this.name});
  final String uid;
  final String? email;
  final String? name;
}

/// Error de autenticación con un mensaje listo para mostrar.
class AuthException implements Exception {
  const AuthException(this.message, {this.cancelled = false});
  final String message;

  /// El usuario cerró la ventana del proveedor: no se muestra como error.
  final bool cancelled;

  @override
  String toString() => message;
}

abstract class AuthService {
  AuthAccount? get current;
  Future<AuthAccount> signInWithGoogle();
  Future<AuthAccount> signInWithApple();
  Future<AuthAccount> signInWithEmail(String email, String password);
  Future<AuthAccount> createWithEmail(String email, String password, {String? name});
  Future<void> sendPasswordReset(String email);
  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _injected = auth;
  final FirebaseAuth? _injected;

  /// Firebase se inicia al arrancar solo si el `.env` trae su configuración.
  FirebaseAuth get _auth {
    if (_injected != null) return _injected;
    if (Firebase.apps.isEmpty) {
      throw const AuthException(
        'Las cuentas no están disponibles en esta versión. Puedes seguir como invitado.',
      );
    }
    return FirebaseAuth.instance;
  }
  bool _googleReady = false;

  AuthAccount _map(User? u) {
    if (u == null) throw const AuthException('No se pudo iniciar sesión.');
    return AuthAccount(uid: u.uid, email: u.email, name: u.displayName);
  }

  @override
  AuthAccount? get current {
    final u = _auth.currentUser;
    return u == null ? null : AuthAccount(uid: u.uid, email: u.email, name: u.displayName);
  }

  Future<AuthAccount> _run(Future<UserCredential> Function() body) async {
    try {
      return _map((await body()).user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e.code));
    }
  }

  @override
  Future<AuthAccount> signInWithEmail(String email, String password) =>
      _run(() => _auth.signInWithEmailAndPassword(email: email, password: password));

  @override
  Future<AuthAccount> createWithEmail(String email, String password, {String? name}) async {
    final account = await _run(
        () => _auth.createUserWithEmailAndPassword(email: email, password: password));
    final clean = name?.trim() ?? '';
    if (clean.isEmpty) return account;
    // El nombre es opcional para Firebase: si falla, la cuenta ya quedó creada.
    try {
      await _auth.currentUser?.updateDisplayName(clean);
    } catch (_) {}
    return AuthAccount(uid: account.uid, email: account.email, name: clean);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e.code));
    }
  }

  @override
  Future<AuthAccount> signInWithGoogle() async {
    try {
      if (!_googleReady) {
        // En Android, Google exige el cliente web del proyecto (serverClientId);
        // en iPhone, el cliente de iOS.
        await GoogleSignIn.instance.initialize(
          clientId: defaultTargetPlatform == TargetPlatform.iOS
              ? _orNull(Env.value('GOOGLE_IOS_CLIENT_ID'))
              : null,
          serverClientId: _orNull(Env.value('GOOGLE_WEB_CLIENT_ID')),
        );
        _googleReady = true;
      }
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw const AuthException('Google no devolvió la credencial.');
      return await _run(() => _auth.signInWithCredential(GoogleAuthProvider.credential(idToken: idToken)));
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Cancelado', cancelled: true);
      }
      debugPrint('Google Sign-In falló: ${e.code} ${e.description}');
      throw const AuthException('No se pudo entrar con Google. Intenta de nuevo.');
    }
  }

  @override
  Future<AuthAccount> signInWithApple() async {
    final rawNonce = _nonce();
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: crypto.sha256.convert(utf8.encode(rawNonce)).toString(),
      );
      final credential = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        rawNonce: rawNonce,
      );
      return await _run(() => _auth.signInWithCredential(credential));
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthException('Cancelado', cancelled: true);
      }
      throw const AuthException('No se pudo entrar con Apple. Intenta de nuevo.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    await _auth.signOut();
  }

  static String _nonce([int length = 32]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final r = Random.secure();
    return List.generate(length, (_) => chars[r.nextInt(chars.length)]).join();
  }

  static String? _orNull(String v) => v.isEmpty ? null : v;

  static String _message(String code) => switch (code) {
        'invalid-email' => 'El correo no es válido.',
        'user-not-found' || 'wrong-password' || 'invalid-credential' =>
          'Correo o contraseña incorrectos.',
        'email-already-in-use' => 'Ya existe una cuenta con ese correo. Prueba iniciar sesión.',
        'weak-password' => 'La contraseña es muy corta (mínimo 6 caracteres).',
        'network-request-failed' => 'Sin conexión. Revisa tu internet e intenta de nuevo.',
        'too-many-requests' => 'Demasiados intentos. Espera un momento.',
        'account-exists-with-different-credential' =>
          'Ese correo ya está registrado con otro método de acceso.',
        _ => 'No se pudo completar. Intenta de nuevo.',
      };
}
