import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_logo.dart';
import 'auth_flow.dart';
import 'register_screen.dart';
import 'widgets/auth_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with AuthFormState {
  var _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!validate(_formKey)) return;
    await runAuth(() async {
      await AuthService.instance.signIn(
        email: _email.text,
        password: _password.text,
      );
      return true;
    });
  }

  Future<void> _openRegister() async {
    // Geçersiz e-posta kayıt formuna taşınmaz.
    final email = AuthValidators.email(_email.text) == null ? _email.text : '';
    setState(() => error = null);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RegisterScreen(initialEmail: email),
      ),
    );
    // Kayıttan geri dönülünce form boş açılır. Alanlar dönüşte temizlenir ki
    // geçiş animasyonu sırasında giriş ekranı boşalmış görünmesin.
    if (!mounted) return;
    _email.clear();
    _password.clear();
    setState(() {
      error = null;
      // Yeni anahtar alan altındaki doğrulama hatalarını da siler.
      _formKey = GlobalKey<FormState>();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      children: [
        const Center(child: AppLogo(size: 64)),
        const SizedBox(height: 28),
        const AuthHeading(
          title: 'Tekrar hoş geldin',
          subtitle: 'Molalarını ve gelişimini kaldığın yerden sürdür.',
        ),
        const SizedBox(height: 28),
        Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthTextField(
                  controller: _email,
                  label: 'E-posta',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: AuthValidators.email,
                  enabled: !anyBusy,
                  onChanged: clearError,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  controller: _password,
                  label: 'Şifre',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  autofillHints: const [AutofillHints.password],
                  textInputAction: TextInputAction.done,
                  validator: AuthValidators.requiredPassword,
                  enabled: !anyBusy,
                  onChanged: clearError,
                  onSubmitted: _submit,
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: anyBusy
                ? null
                : () => showPasswordResetSheet(context, _email.text),
            style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
            child: const Text('Şifremi unuttum'),
          ),
        ),
        if (error case final message?) ...[
          AuthErrorBox(message),
          const SizedBox(height: 14),
        ] else
          const SizedBox(height: 6),
        AuthPrimaryButton(
          label: 'Giriş Yap',
          loading: busy,
          onPressed: anyBusy ? null : _submit,
        ),
        const SizedBox(height: 20),
        const OrDivider(),
        const SizedBox(height: 20),
        GoogleSignInButton(
          loading: googleBusy,
          onPressed: anyBusy ? null : signInWithGoogle,
        ),
        const SizedBox(height: 20),
        AuthSwitchPrompt(
          question: 'Hesabın yok mu?',
          action: 'Kayıt ol',
          onPressed: anyBusy ? null : _openRegister,
        ),
      ],
    );
  }
}

/// E-postaya şifre sıfırlama bağlantısı gönderen alt sayfa.
Future<void> showPasswordResetSheet(BuildContext context, String email) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    builder: (_) => _PasswordResetSheet(initialEmail: email),
  );
}

class _PasswordResetSheet extends StatefulWidget {
  const _PasswordResetSheet({required this.initialEmail});

  final String initialEmail;

  @override
  State<_PasswordResetSheet> createState() => _PasswordResetSheetState();
}

class _PasswordResetSheetState extends State<_PasswordResetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail.trim());
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await AuthService.instance.sendPasswordReset(_email.text);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Bu e-postayla bir hesap varsa şifre sıfırlama bağlantısı '
              'gönderildi.',
            ),
          ),
        );
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Şifreni sıfırla',
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'E-posta adresini yaz, yeni şifre belirlemen için bir '
                      'bağlantı gönderelim.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 18),
                    AuthTextField(
                      controller: _email,
                      label: 'E-posta',
                      icon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.send,
                      validator: AuthValidators.email,
                      enabled: !_busy,
                      onChanged: (_) {
                        if (_error != null) setState(() => _error = null);
                      },
                      onSubmitted: _send,
                    ),
                    if (_error case final message?) ...[
                      const SizedBox(height: 14),
                      AuthErrorBox(message),
                    ],
                    const SizedBox(height: 18),
                    AuthPrimaryButton(
                      label: 'Bağlantı Gönder',
                      loading: _busy,
                      onPressed: _busy ? null : _send,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
