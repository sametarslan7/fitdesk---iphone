import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../firebase_options.dart';

/// Giriş yapmış kullanıcı.
@immutable
class AppUser {
  const AppUser({required this.uid, this.name, this.email});

  final String uid;
  final String? name;
  final String? email;

  /// Ad yoksa e-postanın @ öncesi; ikisi de yoksa null.
  String? get displayName {
    if (name case final name? when name.trim().isNotEmpty) return name.trim();
    if (email case final email? when email.contains('@')) {
      return email.substring(0, email.indexOf('@'));
    }
    return null;
  }

  /// Selamlamalar için ilk ad ("Samet Arslan" → "Samet").
  String? get firstName => displayName?.split(RegExp(r'\s+')).first;

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.uid == uid &&
      other.name == name &&
      other.email == email;

  @override
  int get hashCode => Object.hash(uid, name, email);
}

/// Kullanıcıya gösterilecek Türkçe hata mesajıyla giriş hatası.
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Google ile girişin sonucu.
enum GoogleSignInOutcome {
  /// Kullanıcı Google penceresini kapattı.
  canceled,

  /// Bu Google hesabıyla daha önce açılmış hesaba girildi.
  existingAccount,

  /// İlk kez girildi, yeni hesap açıldı.
  newAccount,
}

/// Hesap işlemlerinin ince sarmalayıcısı. Testler [instance]ı sahtesiyle
/// değiştirir.
abstract class AuthService {
  static AuthService instance = FirebaseAuthService();

  AppUser? get currentUser;

  /// Giriş/çıkışta ve ad değişince yeni değeri yayınlar.
  Stream<AppUser?> get userChanges;

  /// Uygulama açılışında kayıtlı oturum geri yüklenince tamamlanır.
  Future<AppUser?> restoreSession();

  Future<void> signIn({required String email, required String password});

  Future<void> register({
    required String name,
    required String email,
    required String password,
  });

  Future<GoogleSignInOutcome> signInWithGoogle();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

class FirebaseAuthService implements AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;

  Future<void>? _googleReady;

  static AppUser? _toAppUser(User? user) => user == null
      ? null
      : AppUser(uid: user.uid, name: user.displayName, email: user.email);

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Stream<AppUser?> get userChanges => _auth.userChanges().map(_toAppUser);

  @override
  Future<AppUser?> restoreSession() async =>
      _toAppUser(await _auth.authStateChanges().first);

  @override
  Future<void> signIn({required String email, required String password}) =>
      _guard(
        () => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) => _guard(() async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
    // userChanges'in yeni adı yayınlaması için.
    await credential.user?.reload();
  });

  @override
  Future<GoogleSignInOutcome> signInWithGoogle() async {
    if (kIsWeb) {
      return _outcome(
        await _guard(() => _auth.signInWithPopup(GoogleAuthProvider())),
      );
    }
    try {
      await (_googleReady ??= GoogleSignIn.instance.initialize(
        // iOS'ta istemci kimliği Info.plist yerine buradan verilir.
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? DefaultFirebaseOptions.ios.iosClientId
            : null,
      ));
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      return _outcome(
        await _guard(
          () => _auth.signInWithCredential(
            GoogleAuthProvider.credential(idToken: idToken),
          ),
        ),
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return GoogleSignInOutcome.canceled;
      }
      debugPrint('Google ile giriş hatası: $e');
      throw const AuthException(
        'Google ile giriş yapılamadı. Biraz sonra tekrar dene.',
      );
    }
  }

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> signOut() async {
    if (!kIsWeb && _googleReady != null) {
      // Bir sonraki Google girişinde hesap seçici yeniden açılsın.
      await GoogleSignIn.instance.signOut();
    }
    await _auth.signOut();
  }

  static GoogleSignInOutcome _outcome(UserCredential credential) =>
      credential.additionalUserInfo?.isNewUser ?? false
      ? GoogleSignInOutcome.newAccount
      : GoogleSignInOutcome.existingAccount;

  static Future<R> _guard<R>(Future<R> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_message(e.code));
    }
  }

  static String _message(String code) => switch (code) {
    'invalid-email' => 'E-posta adresi geçersiz.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' ||
    'INVALID_LOGIN_CREDENTIALS' => 'E-posta ya da şifre hatalı.',
    'user-disabled' => 'Bu hesap devre dışı bırakılmış.',
    'email-already-in-use' => 'Bu e-posta ile zaten bir hesap var.',
    'weak-password' => 'Şifre en az 6 karakter olmalı.',
    'account-exists-with-different-credential' =>
      'Bu e-posta başka bir giriş yöntemiyle kayıtlı.',
    'too-many-requests' => 'Çok fazla deneme yapıldı. Biraz sonra tekrar dene.',
    'network-request-failed' => 'İnternet bağlantını kontrol et.',
    'popup-closed-by-user' ||
    'cancelled-popup-request' => 'Google penceresi kapatıldı.',
    _ => 'Bir şeyler ters gitti. Tekrar dene.',
  };
}

/// Giriş yapmış kullanıcıyı alt ağaca sağlar; ad değişince dinleyenler
/// yeniden çizilir.
class AuthScope extends InheritedNotifier<ValueNotifier<AppUser?>> {
  const AuthScope({
    super.key,
    required ValueNotifier<AppUser?> user,
    required super.child,
  }) : super(notifier: user);

  static AppUser? userOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier?.value;
}
