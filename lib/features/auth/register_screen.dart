import 'package:flutter/material.dart';

import '../../core/auth/auth_service.dart';
import 'auth_flow.dart';
import 'widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.initialEmail = ''});

  /// Giriş sayfasında yazılmış e-posta tekrar yazılmasın.
  final String initialEmail;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with AuthFormState {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  late final _email = TextEditingController(text: widget.initialEmail.trim());
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!validate(_formKey)) return;
    await runAuth(() async {
      await AuthService.instance.register(
        name: _name.text,
        email: _email.text,
        password: _password.text,
      );
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final back = anyBusy ? null : () => Navigator.of(context).pop();

    // Kayıt sürerken sistem geri tuşu da kapalı; yoksa hesap açılır ama
    // ekran kapandığı için uygulamaya geçilemez.
    return PopScope(
      canPop: !anyBusy,
      child: AuthLayout(
        onBack: back ?? () {},
        children: [
          const AuthHeading(
            title: 'Hesap oluştur',
            subtitle: 'Egzersizlerin ve istatistiklerin hesabında saklansın.',
          ),
          const SizedBox(height: 28),
          Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AuthTextField(
                    controller: _name,
                    label: 'Adın',
                    icon: Icons.person_outline_rounded,
                    autofillHints: const [AutofillHints.givenName],
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: const [WordCapitalizer()],
                    validator: AuthValidators.name,
                    enabled: !anyBusy,
                    onChanged: clearError,
                  ),
                  const SizedBox(height: 14),
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
                    label: 'Şifre (en az 6 karakter)',
                    icon: Icons.lock_outline_rounded,
                    isPassword: true,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    validator: AuthValidators.newPassword,
                    enabled: !anyBusy,
                    onChanged: clearError,
                    onSubmitted: _submit,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (error case final message?) ...[
            AuthErrorBox(message),
            const SizedBox(height: 14),
          ],
          AuthPrimaryButton(
            label: 'Kayıt Ol',
            loading: busy,
            onPressed: anyBusy ? null : _submit,
          ),
          const SizedBox(height: 20),
          const OrDivider(),
          const SizedBox(height: 20),
          GoogleSignInButton(
            loading: googleBusy,
            onPressed: anyBusy
                ? null
                : () => signInWithGoogle(fromRegister: true),
          ),
          const SizedBox(height: 20),
          AuthSwitchPrompt(
            question: 'Zaten hesabın var mı?',
            action: 'Giriş yap',
            onPressed: back,
          ),
        ],
      ),
    );
  }
}
