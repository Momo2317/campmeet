import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camp_meet/core/services/firebase_auth_service.dart';
import 'package:camp_meet/features/home/app_home.dart';
import 'package:camp_meet/features/profile/data/user_profile_repository.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showForgotPasswordSheet() {
    final resetEmailController = TextEditingController();
    String? sheetError;
    bool isSending = false;
    bool isSent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1536),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                if (!isSent) ...[
                  Text('Passwort zurücksetzen',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    'Gib deine registrierte E-Mail-Adresse ein. Wir senden dir einen Link zum Zurücksetzen.',
                    style: TextStyle(
                        fontSize: 14, color: Colors.white54, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  if (sheetError != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4B6E).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFFF4B6E).withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(CupertinoIcons.exclamationmark_circle_fill,
                            color: const Color(0xFFFF4B6E), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(sheetError!,
                                style: TextStyle(
                                    color: const Color(0xFFFF4B6E),
                                    fontSize: 13))),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: TextField(
                      controller: resetEmailController,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      style: TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'name@student.uni.de',
                        hintStyle: TextStyle(color: Colors.white24),
                        prefixIcon: const Icon(CupertinoIcons.envelope_fill,
                            color: Colors.white38, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isSending
                          ? null
                          : () async {
                              final email = resetEmailController.text
                                  .trim()
                                  .toLowerCase();
                              if (email.isEmpty) {
                                setSheetState(() =>
                                    sheetError = 'Bitte E-Mail eingeben.');
                                return;
                              }
                              setSheetState(() {
                                isSending = true;
                                sheetError = null;
                              });
                              try {
                                await FirebaseAuthService()
                                    .resetPassword(email);
                              } on AuthException catch (e) {
                                setSheetState(() {
                                  isSending = false;
                                  sheetError = e.message;
                                });
                                HapticFeedback.heavyImpact();
                                return;
                              }
                              setSheetState(() {
                                isSending = false;
                                isSent = true;
                              });
                              HapticFeedback.lightImpact();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B30FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27)),
                      ),
                      child: isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('Passwort zusenden',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    ),
                  ),
                ] else ...[
                  const Center(
                      child: Icon(CupertinoIcons.checkmark_circle_fill,
                          color: const Color(0xFF2BD9A0), size: 64)),
                  const SizedBox(height: 20),
                  Center(
                      child: Text('E-Mail gesendet',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white))),
                  const SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Wir haben einen Link zum Zurücksetzen an\n${resetEmailController.text.trim()} gesendet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: Colors.white54, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B30FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27)),
                      ),
                      child: Text('Zurück zum Login',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Bitte E-Mail und Passwort eingeben.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuthService().signIn(email: email, password: password);
    } on AuthException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
      HapticFeedback.heavyImpact();
      return;
    }

    // Erfolgreich eingeloggt
    HapticFeedback.lightImpact();
    await ref.read(authSessionProvider.notifier).setLoggedIn(true);
    final current = ref.read(userProfileProvider);
    if (current == null || current.email != email) {
      await ref.read(userProfileProvider.notifier).updateProfile(email: email);
    }
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppHome()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        // Dunkles Gradient-Overlay, damit das Login-Formular gut lesbar bleibt
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0F0B24).withOpacity(0.55),
                const Color(0xFF2A1160).withOpacity(0.85),
                const Color(0xFF0F0B24).withOpacity(0.97),
              ],
            ),
          ),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(CupertinoIcons.chevron_left,
                        color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Expanded(
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        // Logo
                        Center(
                          child: SvgPicture.asset(
                            'assets/images/CampMeet_Login_Logo_1500px.svg',
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Header
                        Text(
                          'Willkommen zurück',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Logge dich mit deiner Uni-E-Mail ein.',
                          style: TextStyle(fontSize: 15, color: Colors.white54),
                        ),
                        const SizedBox(height: 40),

                        // Fehlermeldung
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4B6E).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color:
                                      const Color(0xFFFF4B6E).withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                    CupertinoIcons.exclamationmark_circle_fill,
                                    color: const Color(0xFFFF4B6E),
                                    size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                        color: const Color(0xFFFF4B6E),
                                        fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // E-Mail Feld
                        _buildLabel('E-Mail Adresse'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _emailController,
                          hint: 'name@student.uni.de',
                          icon: CupertinoIcons.envelope_fill,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 20),

                        // Passwort Feld
                        _buildLabel('Passwort'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _passwordController,
                          hint: '••••••••',
                          icon: CupertinoIcons.lock_fill,
                          obscureText: _obscurePassword,
                          onSubmitted: (_) => _login(),
                          suffix: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? CupertinoIcons.eye_slash_fill
                                  : CupertinoIcons.eye_fill,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Passwort vergessen
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordSheet,
                            child: Text(
                              'Passwort vergessen?',
                              style: TextStyle(
                                  color: const Color(0xFFB26BFF), fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF9B30FF),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF9B30FF).withOpacity(0.5),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(27)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : Text(
                                    'Einloggen',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: TextStyle(
            color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffix,
    ValueChanged<String>? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(color: Colors.white, fontSize: 15),
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white24, fontSize: 15),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
