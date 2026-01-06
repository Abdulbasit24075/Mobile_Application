import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  final _firestore = FirebaseFirestore.instance;

  ThemeProvider() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _loadTheme();
    });
  }


  /// ⭐ Load saved theme on startup
  Future<void> _loadTheme() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection("users").doc(user.uid).get();
      if (doc.exists) {
        _isDark = doc.data()?["darkMode"] ?? false;
        notifyListeners();
      }
    } catch (e) {
      print("Error loading theme: $e");
    }
  }

  /// ⭐ FIX #2 — reload theme after login
  Future<void> reloadTheme() async {
    await _loadTheme();
  }

  /// ⭐ Save theme to Firestore
  Future<void> setDarkMode(bool value) async {
    _isDark = value;
    notifyListeners();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection("users").doc(user.uid).set(
        {"darkMode": value},
        SetOptions(merge: true),
      );
    } catch (e) {
      print("Error saving theme: $e");
    }
  }
}
