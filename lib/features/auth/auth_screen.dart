import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _authRedirectUrl = 'pith://auth/callback';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true;
  bool _isSubmitting = false;
  bool _isResettingPassword = false;
  bool _isFeedbackError = false;
  String? _feedback;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isFeedbackError = true;
        _feedback = 'Completa email y clave para continuar.';
      });
      return;
    }

    if (!_isLogin && fullName.isEmpty) {
      setState(() {
        _isFeedbackError = true;
        _feedback = 'Agrega tu nombre para crear tu cuenta.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _isFeedbackError = false;
      _feedback = null;
    });

    try {
      final auth = Supabase.instance.client.auth;
      if (_isLogin) {
        await auth.signInWithPassword(email: email, password: password);
      } else {
        final response = await auth.signUp(
          email: email,
          password: password,
          emailRedirectTo: _authRedirectUrl,
          data: {'full_name': fullName},
        );

        if (response.session == null) {
          setState(() {
            _isFeedbackError = false;
            _feedback = 'Cuenta creada. Revisa tu correo para confirmar e iniciar sesion.';
          });
        }
      }
    } on AuthException catch (error) {
      setState(() {
        _isFeedbackError = true;
        _feedback = _friendlyAuthMessage(error.message);
      });
    } catch (_) {
      setState(() {
        _isFeedbackError = true;
        _feedback = 'No se pudo completar la operacion. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _isFeedbackError = false;
      _feedback = null;
    });
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _isFeedbackError = true;
        _feedback = 'Escribe tu email para recuperar la clave.';
      });
      return;
    }

    setState(() {
      _isResettingPassword = true;
      _isFeedbackError = false;
      _feedback = null;
    });

    try {
        await Supabase.instance.client.auth
          .resetPasswordForEmail(email, redirectTo: _authRedirectUrl);
      setState(() {
        _isFeedbackError = false;
        _feedback = 'Te enviamos un correo para restablecer tu clave.';
      });
    } on AuthException catch (error) {
      setState(() {
        _isFeedbackError = true;
        _feedback = _friendlyAuthMessage(error.message);
      });
    } catch (_) {
      setState(() {
        _isFeedbackError = true;
        _feedback = 'No se pudo enviar el correo de recuperacion. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResettingPassword = false;
        });
      }
    }
  }

  String _friendlyAuthMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'Email o clave invalidos.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Debes confirmar tu email antes de iniciar sesion.';
    }
    if (lower.contains('user already registered')) {
      return 'Ese email ya esta registrado. Inicia sesion o recupera tu clave.';
    }
    if (lower.contains('password should be at least')) {
      return 'La clave debe tener al menos 6 caracteres.';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: ColoredBox(
        color: Color(0xFF070B13),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121C2C).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 28,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Pith',
                        textAlign: TextAlign.center,
                        style: textTheme.displaySmall?.copyWith(
                          color: const Color(0xFFF4EBD0),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _isLogin ? 'Ingresa a tu pCRM privado' : 'Crea tu cuenta para sincronizar en la nube',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF9AA8C0),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _ModeSwitch(isLogin: _isLogin, onToggle: _toggleMode),
                      const SizedBox(height: 22),
                      if (!_isLogin) ...[
                        _AuthField(
                          controller: _nameController,
                          hint: 'Nombre completo',
                          icon: Icons.badge_rounded,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _AuthField(
                        controller: _emailController,
                        hint: 'Email',
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      _AuthField(
                        controller: _passwordController,
                        hint: 'Clave',
                        icon: Icons.lock_rounded,
                        obscureText: true,
                        keyboardType: TextInputType.visiblePassword,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _submit(),
                      ),
                      if (_isLogin) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isSubmitting || _isResettingPassword
                                ? null
                                : _resetPassword,
                            child: _isResettingPassword
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Text('Olvide mi clave'),
                          ),
                        ),
                      ],
                      if (_feedback != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                          decoration: BoxDecoration(
                            color: _isFeedbackError
                                ? const Color(0x26F06A6A)
                                : const Color(0x1AF4C025),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isFeedbackError
                                  ? const Color(0x66F06A6A)
                                  : const Color(0x66F4C025),
                            ),
                          ),
                          child: Text(
                            _feedback!,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(
                              color: _isFeedbackError
                                  ? const Color(0xFFFFB7B7)
                                  : const Color(0xFFF4EBD0),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 52,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFF4C025),
                            foregroundColor: const Color(0xFF17130A),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 0.2,
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.6,
                                    color: Color(0xFF17130A),
                                  ),
                                )
                              : Text(_isLogin ? 'Ingresar' : 'Crear cuenta'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.isLogin, required this.onToggle});

  final bool isLogin;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeChip(
            label: 'Login',
            selected: isLogin,
            onTap: isLogin ? null : onToggle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModeChip(
            label: 'Registro',
            selected: !isLogin,
            onTap: isLogin ? onToggle : null,
          ),
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF4C025) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF17130A) : const Color(0xFF9AA8C0),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: Color(0xFFF4EBD0),
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xAA9AA8C0)),
        prefixIcon: Icon(icon, color: const Color(0xAA9AA8C0)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          borderSide: BorderSide(color: Color(0xFFF4C025), width: 1.3),
        ),
      ),
    );
  }
}
