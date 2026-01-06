import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController(); // ⭐ NEW CONFIRM PASSWORD FIELD

  bool loading = false;

  bool isValidEmail(String email) {
    final regex = RegExp(
        r"^[A-Za-z](?:[A-Za-z0-9._-]*[A-Za-z0-9])?@gmail\.com$"
    );
    return regex.hasMatch(email);
  }

  Future<void> signup() async {
    // ---- VALIDATION BEFORE FIREBASE ----

    // 1️⃣ Validate Email Format
    if (!isValidEmail(emailCtrl.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "Invalid email!\nUse format: letters (symbols , digits)-> allowed only after letters.\nExample: basit_subhani123@gmail.com"
          ),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // 2️⃣ Validate Password Match
    if (passCtrl.text.trim() != confirmPassCtrl.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      // 3️⃣ Create User (same as before)
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailCtrl.text.trim(),
        password: passCtrl.text.trim(),
      );

      // Force logout to ensure manual login
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created successfully! Please log in."),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Signup failed: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

    if (mounted) setState(() => loading = false);
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
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ).animate().fade(duration: 300.ms),

                  Icon(
                    Icons.person_add_alt_1_outlined,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.9),
                  )
                      .animate()
                      .scale(duration: 600.ms, curve: Curves.easeOutBack)
                      .fade(duration: 400.ms),

                  const SizedBox(height: 20),

                  const Text(
                    "Join WeatherWhiz",
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
                    "Create your account to get started",
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
                        // EMAIL INPUT
                        TextField(
                          controller: emailCtrl,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: "username@gmail.com",
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

                        // PASSWORD INPUT
                        TextField(
                          controller: passCtrl,
                          obscureText: true,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: "Create Password",
                            labelStyle: TextStyle(color: labelColor),
                            prefixIcon: Icon(Icons.lock_outline, color: iconColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: fillColor,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ⭐ NEW CONFIRM PASSWORD FIELD
                        TextField(
                          controller: confirmPassCtrl,
                          obscureText: true,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: "Confirm Password",
                            labelStyle: TextStyle(color: labelColor),
                            prefixIcon: Icon(Icons.lock_reset_rounded, color: iconColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: fillColor,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // SIGNUP BUTTON
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: loading ? null : signup,
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
                              "SIGN UP",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fade(delay: 400.ms, duration: 500.ms)
                      .slideY(begin: 0.2, end: 0)
                      .shimmer(
                      delay: 1500.ms,
                      duration: 1200.ms,
                      color: Colors.white.withValues(alpha: 0.8)),

                  const SizedBox(height: 20),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: const TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(
                            text: "Log In",
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
