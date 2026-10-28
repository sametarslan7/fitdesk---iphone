import 'dart:async';

import 'package:fitdesk/core/auth/auth_service.dart';
import 'package:fitdesk/core/data/activity_cloud.dart';

/// Bellekte çalışan giriş servisi; varsayılan olarak bir kullanıcı girişli.
class FakeAuthService implements AuthService {
  FakeAuthService({AppUser? user = testUser}) : _user = user;

  static const testUser = AppUser(
    uid: 'test-uid',
    name: 'Deniz Yılmaz',
    email: 'deniz@example.com',
  );

  AppUser? _user;
  final _changes = StreamController<AppUser?>.broadcast();

  /// Kayıtlı hesaplar: e-posta → şifre.
  final accounts = <String, String>{'deniz@example.com': 'gizli123'};
  bool googleCancels = false;

  /// Kayıt sürerken yapılan işlemleri denemek için bekleme.
  Duration registerDelay = Duration.zero;

  /// Google hesabıyla daha önce girilmiş mi.
  bool googleAccountExists = false;
  final resetEmails = <String>[];

  void _set(AppUser? user) {
    _user = user;
    _changes.add(user);
  }

  @override
  AppUser? get currentUser => _user;

  @override
  Stream<AppUser?> get userChanges => _changes.stream;

  @override
  Future<AppUser?> restoreSession() async => _user;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (accounts[email.trim()] != password) {
      throw const AuthException('E-posta ya da şifre hatalı.');
    }
    _set(AppUser(uid: 'uid-${email.trim()}', email: email.trim()));
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(registerDelay);
    if (accounts.containsKey(email.trim())) {
      throw const AuthException('Bu e-posta ile zaten bir hesap var.');
    }
    accounts[email.trim()] = password;
    _set(AppUser(uid: 'uid-${email.trim()}', name: name, email: email.trim()));
  }

  @override
  Future<GoogleSignInOutcome> signInWithGoogle() async {
    if (googleCancels) return GoogleSignInOutcome.canceled;
    _set(
      const AppUser(
        uid: 'google-uid',
        name: 'Ada Kaya',
        email: 'ada@gmail.com',
      ),
    );
    final existed = googleAccountExists;
    googleAccountExists = true;
    return existed
        ? GoogleSignInOutcome.existingAccount
        : GoogleSignInOutcome.newAccount;
  }

  @override
  Future<void> sendPasswordReset(String email) async => resetEmails.add(email);

  @override
  Future<void> signOut() async => _set(null);
}

/// Hesaplara göre ayrılmış, bellekte tutulan bulut kaydı.
class FakeActivityCloud implements ActivityCloud {
  FakeActivityCloud._(this._records);

  /// uid → kayıtlar (belge kimliğiyle, Firestore gibi tekilleştirilmiş).
  static final store = <String, Map<String, ActivityRecord>>{};

  static ActivityCloud forUser(String uid) =>
      FakeActivityCloud._(store.putIfAbsent(uid, () => {}));

  final Map<String, ActivityRecord> _records;
  final _watchers = <StreamController<List<ActivityRecord>>>{};

  @override
  Stream<List<ActivityRecord>> watch() {
    late final StreamController<List<ActivityRecord>> controller;
    controller = StreamController(
      onListen: () {
        controller.add(_records.values.toList());
        _watchers.add(controller);
      },
      onCancel: () => _watchers.remove(controller),
    );
    return controller.stream;
  }

  @override
  Future<void> addAll(List<ActivityRecord> records) async {
    for (final r in records) {
      _records['${r.at.millisecondsSinceEpoch}_${r.exerciseId}'] = r;
    }
    for (final watcher in _watchers) {
      watcher.add(_records.values.toList());
    }
  }
}

/// Testlerde Firebase yerine sahteleri kullanır; [user] null ise çıkış
/// yapılmış başlanır.
FakeAuthService useFakeBackend({AppUser? user = FakeAuthService.testUser}) {
  FakeActivityCloud.store.clear();
  ActivityCloud.forUser = FakeActivityCloud.forUser;
  final auth = FakeAuthService(user: user);
  AuthService.instance = auth;
  return auth;
}
