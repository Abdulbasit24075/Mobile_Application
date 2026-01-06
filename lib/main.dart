import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'providers/theme_provider.dart';
import 'services/weather_widget_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await WeatherWidgetManager.initialize();
  // 🔥 YOUR LOGIC: Force sign out on app start
  // This means the user will ALWAYS see the Login Screen first.
  await FirebaseAuth.instance.signOut();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const WeatherApp(),
    ),
  );
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WeatherWhiz',

      // Theme Setup
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(),
        useMaterial3: true,
      ),
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,

      // ⭐ CHANGE: Start directly with the AuthWrapper.
      // The "Second Screen" (SplashScreen widget) has been removed.
      home: const AuthWrapper(),
    );
  }
}

// --- THE AUTH WRAPPER ---
// This decides whether to show Login or Home immediately
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. While Firebase is checking (Loading state)
        // We show a plain white spinner so the user doesn't see a "Login" flash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. If logged in -> Home
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // 3. If not logged in -> Login
        return const LoginScreen();
      },
    );
  }
}