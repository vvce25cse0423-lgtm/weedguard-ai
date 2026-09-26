import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/errors/app_error.dart';
import '../../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final repo = AuthRepository(Supabase.instance.client);
      await repo.signIn(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
      if (mounted) context.go('/');
    } on AppError catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Sign in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/login_bg.png', fit: BoxFit.cover),
          Container(color: const Color(0x22A5D6A7)),
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: screenH * 0.055),
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.55),
                        border: Border.all(color: const Color(0xFF81C784), width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 42),
                    ),
                    const SizedBox(height: 14),
                    RichText(
                      text: const TextSpan(children: [
                        TextSpan(text: 'WeedGuard ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF1B2B1B))),
                        TextSpan(text: 'AI', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF2E7D32))),
                      ]),
                    ),
                    const SizedBox(height: 6),
                    const Text('Smarter Fields. Healthier Crops.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF3E5C3E), fontWeight: FontWeight.w600, letterSpacing: 0.4)),
                    SizedBox(height: screenH * 0.038),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF81C784), width: 1.5),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 24, offset: const Offset(0, 8))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Welcome Back',
                                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1B2B1B))),
                                  const SizedBox(height: 6),
                                  const Text('Sign in to monitor your fields and weed health.',
                                    style: TextStyle(fontSize: 13, color: Color(0xFF3E5C3E), fontWeight: FontWeight.w500, height: 1.5)),
                                  const SizedBox(height: 22),
                                  if (_error != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: const Color(0xFFEF9A9A)),
                                      ),
                                      child: Row(children: [
                                        const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFC62828), fontSize: 12))),
                                      ]),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  _GlassField(controller: _emailCtrl, hint: 'Email address', prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) {
                                      if (v == null || v.trim().isEmpty) return 'Email is required';
                                      if (!v.contains('@')) return 'Enter a valid email';
                                      return null;
                                    }),
                                  const SizedBox(height: 14),
                                  _GlassField(
                                    controller: _passwordCtrl, hint: 'Password', prefixIcon: Icons.lock_outline,
                                    obscureText: _obscurePassword,
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                          color: const Color(0xFF4A7A4A), size: 20),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Password is required';
                                      return null;
                                    }),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () => context.push('/forgot-password'),
                                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF2E7D32),
                                          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6)),
                                      child: const Text('Forgot password?',
                                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: double.infinity, height: 54,
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF2E7D32),
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: const Color(0xFF2E7D32).withOpacity(0.6),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        elevation: 2,
                                      ),
                                      child: _loading
                                          ? const SizedBox(width: 22, height: 22,
                                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                              Text('Sign in', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                                              SizedBox(width: 8),
                                              Icon(Icons.arrow_forward, size: 18),
                                            ]),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                    const Text("Don't have an account?",
                                        style: TextStyle(fontSize: 13, color: Color(0xFF3E5C3E), fontWeight: FontWeight.w600)),
                                    TextButton(
                                      onPressed: () => context.push('/signup'),
                                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF2E7D32),
                                          padding: const EdgeInsets.symmetric(horizontal: 6)),
                                      child: const Text('Create account',
                                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                    ),
                                  ]),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: screenH * 0.04),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Better decisions for your crops',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Color(0xFF1B5E20), fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _GlassField({
    required this.controller, required this.hint, required this.prefixIcon,
    this.obscureText = false, this.suffixIcon, this.keyboardType, this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1B2B1B), fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF7A9A7A), fontSize: 14),
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF4A7A4A), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.85),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB2DFDB), width: 1.2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB2DFDB), width: 1.2)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF9A9A), width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF9A9A), width: 2)),
        errorStyle: const TextStyle(color: Color(0xFFC62828)),
      ),
    );
  }
}
