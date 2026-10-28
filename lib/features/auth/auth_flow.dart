import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/navigation/fade_route.dart';
import '../shell/main_shell.dart';
import 'login_screen.dart';

/// Girişten sonra uygulamaya geçer; geri tuşu giriş sayfasına dönmez.
void enterApp(BuildContext context) {
  Navigator.of(
    context,
    rootNavigator: true,
  ).pushAndRemoveUntil(fadeRoute(const MainShell()), (_) => false);
}

/// Çıkıştan sonra (sekme içinden de) giriş sayfasına döner.
void showLogin(BuildContext context) {
  Navigator.of(
    context,
    rootNavigator: true,
  ).pushAndRemoveUntil(fadeRoute(const LoginScreen()), (_) => false);
}

/// Giriş ve kayıt formlarının ortak yükleniyor/hata durumu.
mixin AuthFormState<T extends StatefulWidget> on State<T> {
  bool busy = false;
  bool googleBusy = false;
  String? error;

  bool get anyBusy => busy || googleBusy;

  /// Form hatalıysa önceki sunucu hatası da silinir; yoksa ekranda eski ve
  /// yeni hata birlikte kalır.
  bool validate(GlobalKey<FormState> formKey) {
    if (formKey.currentState!.validate()) return true;
    if (error != null) setState(() => error = null);
    return false;
  }

  /// Kullanıcı bir alana yazmaya başlayınca sunucu hatası kaybolur.
  void clearError(String _) {
    if (error != null) setState(() => error = null);
  }

  /// [action] true dönerse uygulamaya geçilir; false (ör. Google penceresi
  /// kapatıldı) sessizce bekler.
  Future<void> runAuth(
    Future<bool> Function() action, {
    bool google = false,
  }) async {
    if (anyBusy) return;
    FocusScope.of(context).unfocus();
    setState(() {
      error = null;
      google ? googleBusy = true : busy = true;
    });
    try {
      if (await action() && mounted) {
        enterApp(context);
        return;
      }
    } on AuthException catch (e) {
      error = e.message;
    }
    if (mounted) {
      setState(() => busy = googleBusy = false);
    }
  }

  /// [fromRegister]: kayıt sayfasından var olan hesaba girilirse kullanıcı
  /// yeniden kayıt olduğunu sanmasın diye uyarılır.
  Future<void> signInWithGoogle({bool fromRegister = false}) =>
      runAuth(() async {
        final outcome = await AuthService.instance.signInWithGoogle();
        if (fromRegister &&
            outcome == GoogleSignInOutcome.existingAccount &&
            mounted) {
          // Uyarı uygulamaya geçildikten sonra da görünür kalır.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Bu Google hesabıyla zaten bir hesabın vardı, giriş yapıldı.',
              ),
            ),
          );
        }
        return outcome != GoogleSignInOutcome.canceled;
      }, google: true);
}
