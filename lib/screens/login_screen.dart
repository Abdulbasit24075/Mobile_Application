import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'signup_screen.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  bool guestLoading = false;

  Future<void> login() async {
    setState(() => loading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      if (mounted) {
        await Provider.of<ThemeProvider>(context, listen: false).reloadTheme();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login failed: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> loginAsGuest() async {
    setState(() => guestLoading = true);

    try {
      // Sign in anonymously
      await FirebaseAuth.instance.signInAnonymously();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Signed in as Guest"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Guest login failed: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    if (mounted) setState(() => guestLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    // Get theme-aware colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.grey.shade900 : Colors.blue.shade400;
    final backgroundColorEnd = isDark ? Colors.black : Colors.blue.shade900;
    final cardColor = isDark ? Colors.grey.shade800 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final labelColor = isDark ? Colors.grey.shade400 : Colors.grey.shade700;
    final fillColor = isDark ? Colors.grey.shade700 : Colors.grey.shade50;
    final iconColor = isDark ? Colors.grey.shade400 : Colors.grey;
    final dividerColor = isDark ? Colors.grey.shade600 : Colors.grey.shade300;
    final orTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final buttonBorderColor = isDark ? Colors.blue.shade400 : Colors.blue.shade800;
    final buttonTextColor = isDark ? Colors.blue.shade300 : Colors.blue.shade800;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [backgroundColor, backgroundColorEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_outlined,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.9),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.easeOutBack)
                      .fade(duration: 400.ms),

                  const SizedBox(height: 20),

                  const Text(
                    "Welcome Back",
                    style: TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  )
                      .animate()
                      .fade(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: -0.2, end: 0),

                  const Text(
                    "Sign in to continue to WeatherWhiz",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ).animate().fade(delay: 300.ms),

                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        // Email Input
                        TextField(
                          controller: emailCtrl,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: "Email Address",
                            labelStyle: TextStyle(color: labelColor),
                            prefixIcon: Icon(Icons.email_outlined, color: iconColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: fillColor,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password Input
                        TextField(
                          controller: passCtrl,
                          obscureText: true,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: "Password",
                            labelStyle: TextStyle(color: labelColor),
                            prefixIcon: Icon(Icons.lock_outline, color: iconColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: fillColor,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loading || guestLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: loading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                                : const Text(
                              "LOGIN",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Divider with "OR"
                        Row(
                          children: [
                            Expanded(child: Divider(color: dividerColor, thickness: 1)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "OR",
                                style: TextStyle(
                                  color: orTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: dividerColor, thickness: 1)),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Guest Mode Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: loading || guestLoading ? null : loginAsGuest,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: buttonTextColor,
                              side: BorderSide(color: buttonBorderColor, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: guestLoading
                                ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: buttonTextColor,
                              ),
                            )
                                : Icon(Icons.person_outline, size: 20, color: buttonTextColor),
                            label: Text(
                              guestLoading ? "SIGNING IN..." : "CONTINUE AS GUEST",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: buttonTextColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fade(delay: 400.ms, duration: 500.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(
                            text: "Sign Up",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fade(delay: 600.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}