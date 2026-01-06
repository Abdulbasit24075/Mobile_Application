import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/theme_provider.dart';
import 'meditation_form_screen.dart';
import 'meditation_choose_sound_screen.dart';
import 'user_alerts.dart';
import 'clothing_suggestion_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Existing variables
  String userCity = "--";
  bool loadingCity = true;
  String meditationSound = "--";
  bool loadingMeditation = true;

  final _player = AudioPlayer();
  Timer? _countdownTimer;

  /// 🔥 NEW — Replaces _meditationDuration
  Duration _selectedTimerDuration = const Duration(minutes: 1);

  Duration _currentCountdown = Duration.zero;
  bool _isPlaying = false;

  String userDob = "--";
  bool loadingDob = true;

  @override
  void initState() {
    super.initState();
    _loadUserCity();
    _loadMeditationSound();
    _loadDob();
  }

  // --- UI Build ---
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Dynamic Gradient based on theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? [const Color(0xFF1A233A), const Color(0xFF151925)]
        : [Colors.blue.shade900, Colors.blue.shade600, Colors.blue.shade400];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("My Profile",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 10),

                _buildProfileCard(user, themeProvider)
                    .animate()
                    .fadeIn()
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                          "Age",
                          loadingDob ? "..." : _calculateAge(userDob),
                          Icons.cake,
                          _editDobDialog,
                          200),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoCard("City", loadingCity ? "..." : userCity,
                          Icons.location_city, _editCityDialog, 300),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildMeditationCard()
                    .animate()
                    .fadeIn(delay: 400.ms)
                    .slideY(begin: 0.2, end: 0),
                const SizedBox(height: 20),

                _buildActionButton(
                  "Weather Safety Alerts",
                  Icons.warning_amber_rounded,
                  Colors.deepOrange.shade400,
                      () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const UserAlertsScreen())),
                  500,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  "Clothing Suggestions",
                  Icons.checkroom,
                  Colors.teal.shade400,
                      () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ClothingSuggestionScreen())),
                  600,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildProfileCard(User? user, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Icon(Icons.person_rounded, size: 50, color: Colors.blue),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user == null
                ? "Guest User"
                : user.email!.split('@')[0], // ⭐ Extract only username
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            "Weather Enthusiast",
            style: TextStyle(
                fontSize: 14, color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Dark Mode", style: TextStyle(color: Colors.white)),
                const SizedBox(width: 10),
                Switch(
                  value: themeProvider.isDark,
                  activeThumbColor: Colors.blue.shade200,
                  activeTrackColor: Colors.blue.shade800,
                  onChanged: (value) => themeProvider.setDarkMode(value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String label, String value, IconData icon, VoidCallback onTap, int delay) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 24),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 14, color: Colors.white.withValues(alpha: 0.6))),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildMeditationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Mindfulness",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Icon(Icons.self_improvement,
                  color: Colors.white.withValues(alpha: 0.8)),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loadingMeditation ? "Loading..." : meditationSound,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),

                    if (_isPlaying)
                      Text(
                        _formatDuration(_currentCountdown),
                        style: TextStyle(
                            fontSize: 14, color: Colors.greenAccent.shade200),
                      ),
                  ],
                ),
              ),

              IconButton(
                onPressed: _isPlaying ? _stopMeditation : _playMeditation,
                icon: Icon(
                    _isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline,
                    size: 40,
                    color: Colors.white),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isPlaying
                      ? null
                      : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              MeditationChooseSoundScreen(onSelected: _saveMeditation))),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Change"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isPlaying
                      ? null
                      : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              MeditationFormScreen(onResult: _saveMeditation))),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Suggest"),
                ),
              ),
            ],
          ),

          // 🔥 New Timer Button
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _isPlaying ? null : _showTimerSelectionDialog,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
              foregroundColor: Colors.white,
            ),
            child: Text("Set Timer (${_selectedTimerDuration.inMinutes} min)"),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap, int delay) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.7)]),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                const SizedBox(width: 16),
                Text(label,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const Spacer(),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2, end: 0);
  }

  // --- Logic Methods (Updated) ---

  Future<void> _loadDob() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc =
      await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          userDob = doc.data()?["dob"] ?? "--";
          loadingDob = false;
        });
      } else if (mounted) {
        setState(() => loadingDob = false);
      }
    } catch (_) {
      if (mounted) setState(() => loadingDob = false);
    }
  }

  Future<void> _editDobDialog() async {
    DateTime initialDate =
    DateTime.now().subtract(const Duration(days: 365 * 18));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(data: ThemeData.dark(), child: child!),
    );

    if (picked != null && mounted) {
      String formatted =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .set({"dob": formatted}, SetOptions(merge: true));
        if (mounted) setState(() => userDob = formatted);
      }
    }
  }

  String _calculateAge(String dob) {
    if (dob == "--") return "--";
    try {
      final parts = dob.split("-");
      DateTime birthDate =
      DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return "$age years";
    } catch (_) {
      return "--";
    }
  }

  Future<void> _loadUserCity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc =
      await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          userCity = doc.data()?["city"] ?? "--";
          loadingCity = false;
        });
      } else if (mounted) {
        setState(() => loadingCity = false);
      }
    } catch (_) {
      if (mounted) setState(() => loadingCity = false);
    }
  }

  Future<void> _loadMeditationSound() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc =
      await FirebaseFirestore.instance.collection("users").doc(user.uid).get();
      if (doc.exists && mounted) {
        setState(() {
          meditationSound = doc.data()?["meditationSound"] ?? "--";
          loadingMeditation = false;
        });
      } else if (mounted) {
        setState(() => loadingMeditation = false);
      }
    } catch (_) {
      if (mounted) setState(() => loadingMeditation = false);
    }
  }

  Future<void> _saveMeditation(String soundName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .set({"meditationSound": soundName}, SetOptions(merge: true));
    if (mounted) setState(() => meditationSound = soundName);
  }

  Future<void> _editCityDialog() async {
    final controller = TextEditingController(text: userCity);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Update City", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              labelText: "City name",
              labelStyle: TextStyle(color: Colors.white70),
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white54))),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newCity = controller.text.trim();
              if (newCity.isNotEmpty) {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(user.uid)
                      .set({"city": newCity}, SetOptions(merge: true));
                  if (mounted) setState(() => userCity = newCity);
                }
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 🔥 UPDATED — Play Meditation with Selected Timer Duration
  // -------------------------------------------------------------

  Future<void> _playMeditation() async {
    if (meditationSound == "--" || _isPlaying) return;
    try {
      await _player.setAsset("assets/sounds/$meditationSound.mp3");
      await _player.setLoopMode(LoopMode.one);
      _player.play();

      setState(() {
        _isPlaying = true;
        _currentCountdown = _selectedTimerDuration;
      });

      _countdownTimer =
          Timer.periodic(const Duration(seconds: 1), (timer) {
            if (_currentCountdown.inSeconds <= 0) {
              _stopMeditation();
            } else if (mounted) {
              setState(() {
                _currentCountdown -= const Duration(seconds: 1);
              });
            }
          });
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _stopMeditation() async {
    _countdownTimer?.cancel();
    await _player.stop();

    if (mounted) {
      setState(() {
        _isPlaying = false;
        _currentCountdown = Duration.zero;
      });
    }
  }

  // -------------------------------------------------------------
  // 🔥 NEW — Timer Selection Dialog
  // -------------------------------------------------------------

  void _showTimerSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title:
          const Text("Select Timer Duration", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _timerOption(5),
              _timerOption(10),
              _timerOption(15),
              _timerOption(20),
            ],
          ),
        );
      },
    );
  }

  Widget _timerOption(int minutes) {
    return ListTile(
      title: Text("$minutes minutes",
          style: const TextStyle(color: Colors.white)),
      onTap: () {
        setState(() {
          _selectedTimerDuration = Duration(minutes: minutes);
        });
        Navigator.pop(context);
      },
    );
  }

  String _formatDuration(Duration d) =>
      "${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _player.dispose();
    super.dispose();
  }
}
