import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/text_utils.dart';

/// Tablette form aşırı yayılmasın.
const _maxFormWidth = 440.0;

/// Giriş ve kayıt sayfalarının ortak iskeleti: açılış ekranıyla aynı yumuşak
/// arka plan, ortalanmış ve klavye açılınca kayan içerik. Boş bir yere
/// dokununca alandan çıkılır ve klavye kapanır.
class AuthLayout extends StatelessWidget {
  const AuthLayout({super.key, required this.children, this.onBack});

  final List<Widget> children;

  /// Verilirse sol üstte geri butonu gösterilir.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(-0.9, -0.9),
              radius: 1.2,
              colors: [Color(0xFFDDF6E9), AppColors.surface],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 48,
                      ),
                      child: ResponsiveCenter(
                        maxWidth: _maxFormWidth,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Geri butonunun altında kalmasın.
                            if (onBack != null) const SizedBox(height: 32),
                            ...children,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (onBack != null)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: IconButton(
                      onPressed: onBack,
                      tooltip: 'Geri',
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sayfa başlığı ve altındaki kısa açıklama.
class AuthHeading extends StatelessWidget {
  const AuthHeading({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class AuthTextField extends StatefulWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.isPassword = false,
    this.enabled = true,
    this.onSubmitted,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool isPassword;
  final bool enabled;
  final VoidCallback? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscured = true;
  final _focus = FocusNode();
  final _fieldKey = GlobalKey<FormFieldState<String>>();
  bool _hideError = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_trimEmailOnBlur);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// E-postanın başında/sonunda kalan boşluklar alandan çıkınca silinir.
  void _trimEmailOnBlur() {
    if (_focus.hasFocus || widget.keyboardType != TextInputType.emailAddress) {
      return;
    }
    final text = widget.controller.text;
    if (text.trim() != text) widget.controller.text = text.trim();
  }

  /// Alan altındaki uyarı, kullanıcı alanı düzeltmeye başlayınca kaybolur;
  /// bir sonraki gönderimde yeniden denetlenir.
  void _onChanged(String value) {
    final field = _fieldKey.currentState;
    if (field != null && field.hasError) {
      _hideError = true;
      field.validate();
      _hideError = false;
    }
    widget.onChanged?.call(value);
  }

  static OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: _fieldKey,
      controller: widget.controller,
      focusNode: _focus,
      validator: (value) => _hideError ? null : widget.validator?.call(value),
      onChanged: _onChanged,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      inputFormatters: widget.inputFormatters,
      obscureText: widget.isPassword && _obscured,
      autocorrect: !widget.isPassword,
      enableSuggestions: !widget.isPassword,
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
      decoration: InputDecoration(
        labelText: widget.label,
        // Uzun uyarılar "…" ile kesilmesin, alt satıra insin; dar ekran ve
        // büyük sistem yazı boyutunda da sığsın diye pay bırakıldı.
        errorMaxLines: 5,
        prefixIcon: Icon(widget.icon, color: AppColors.onSurfaceVariant),
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () => setState(() => _obscured = !_obscured),
                tooltip: _obscured ? 'Şifreyi göster' : 'Şifreyi gizle',
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.onSurfaceVariant,
                ),
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: _border(AppColors.outlineVariant),
        enabledBorder: _border(AppColors.outlineVariant),
        disabledBorder: _border(AppColors.surfaceContainerHigh),
        focusedBorder: _border(AppColors.primaryContainer, 2),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, 2),
      ),
    );
  }
}

/// Sunucudan dönen hatanın gösterildiği kutu.
class AuthErrorBox extends StatelessWidget {
  const AuthErrorBox(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.all(Radius.circular(14)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF410002)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yükleniyorken yazının yerine dönen gösterge çıkan ana buton.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      child: loading
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.onPrimary,
              ),
            )
          : Text(label),
    );
  }
}

/// "veya" ayırıcısı.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.outlineVariant)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'veya',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.outlineVariant)),
      ],
    );
  }
}

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final bool loading;

  // Google'ın renkli "G" işareti.
  static const _logo =
      '<svg viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 '
      '1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 '
      '13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/><path fill="#4285F4" '
      'd="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 '
      '5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/><path '
      'fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76'
      '-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97'
      '-6.19z"/><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-'
      '7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 '
      '6.19C6.51 42.62 14.62 48 24 48z"/></svg>';

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: const StadiumBorder(),
        backgroundColor: AppColors.surfaceContainerLowest,
        foregroundColor: AppColors.onSurface,
        side: const BorderSide(color: AppColors.outlineVariant),
        textStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontSize: 16),
      ),
      child: loading
          ? const SizedBox.square(
              dimension: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.string(_logo, width: 20, height: 20),
                const SizedBox(width: 12),
                const Flexible(
                  child: Text(
                    'Google ile devam et',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
    );
  }
}

/// "Hesabın yok mu? Kayıt ol" gibi alt satır.
class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    super.key,
    required this.question,
    required this.action,
    required this.onPressed,
  });

  final String question;
  final String action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          question,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
          child: Text(
            action,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Form doğrulamaları.
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? value) =>
      _email.hasMatch(value?.trim() ?? '') ? null : 'Geçerli bir e-posta gir.';

  static String? requiredPassword(String? value) =>
      (value ?? '').isEmpty ? 'Şifreni gir.' : null;

  static final _passwordChars = RegExp(r'^[A-Za-z0-9_.]*$');

  static String? newPassword(String? value) {
    final password = value ?? '';
    if (!_passwordChars.hasMatch(password)) {
      return 'Şifrede yalnızca harf (Türkçe karakter hariç), rakam, _ ve . '
          'kullanılabilir.';
    }
    if (password.length < 6) return 'Şifre en az 6 karakter olmalı.';
    return null;
  }

  static String? name(String? value) =>
      (value ?? '').trim().isEmpty ? 'Adını gir.' : null;
}

/// Her kelimenin ilk harfini Türkçe kurallarıyla büyütür ("ilker" → "İlker").
/// Bazı klavyeler [TextCapitalization.words] ayarını yok saydığı için gerekli.
class WordCapitalizer extends TextInputFormatter {
  const WordCapitalizer();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final chars = newValue.text.split('');
    for (var i = 0; i < chars.length; i++) {
      if (i > 0 && chars[i - 1].trim().isNotEmpty) continue;
      final upper = TextUtils.upper(chars[i]);
      // "ß" gibi büyüyünce uzayan harfler imleci kaydırmasın.
      if (upper.length == 1) chars[i] = upper;
    }
    return newValue.copyWith(text: chars.join());
  }
}
