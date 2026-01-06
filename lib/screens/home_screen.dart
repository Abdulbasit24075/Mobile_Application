import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/weather_service.dart';
import 'city_search_screen.dart';
import 'chat_screen.dart';
import 'weather_detail_screen.dart';
import 'add_location_screen.dart';
import 'choose_city_by_map.dart';
import 'profile_screen.dart';
import '../services/weather_widget_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherService _svc = WeatherService();
  bool _loading = false;
  String? _error;
  DateTime? _lastTap;
  bool _searchLoading = false;

  bool _allowTap([int ms = 1000]) {
    final now = DateTime.now();
    if (_lastTap == null || now.difference(_lastTap!) > Duration(milliseconds: ms)) {
      _lastTap = now;
      return true;
    }
    return false;
  }

  Future<void> _loadByCity(String city) async {
    if (!_allowTap()) return;
    setState(() {
      _loading = true;
      _searchLoading = true;
    });

    try {
      final d = await _svc.byCity(city);
      _error = null;
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => WeatherDetailScreen(weatherData: d)));
    } catch (e) {
      _error = "City not found";
    } finally {
      if (mounted) setState(() { _loading = false; _searchLoading = false; });
    }
  }

  Future<void> _loadByLocation() async {
    if (!_allowTap()) return;
    setState(() => _loading = true);

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception("Enable GPS");

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw Exception("Permission denied");
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 100,
      );

      final pos = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
      final d = await _svc.byCoords(pos.latitude, pos.longitude);

      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => WeatherDetailScreen(weatherData: d)));

    } catch (e) {
      setState(() => _error = "Location Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }
  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();

        final savedCity = doc.data()?["city"] ?? "Lahore";

        await WeatherWidgetManager.updateWidgetWithCity(savedCity);

        print("🏡 Widget updated automatically for HomeScreen (city: $savedCity)");
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = isDark
        ? [const Color(0xFF1A233A), const Color(0xFF151925)]
        : [Colors.blue.shade900, Colors.blue.shade600, Colors.blue.shade400];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              tooltip: "Sign Out",
              onPressed: _handleLogout,
            ),
          ),
        ],
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.cloud_queue_rounded, size: 60, color: Colors.white),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                const SizedBox(height: 20),

                const Text(
                  "WeatherWhiz",
                  style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                Text(
                  "Your personal forecast assistant",
                  style: TextStyle(fontSize: 16, color: Colors.white.withValues(alpha: 0.8)),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 50),

                _mainButton(
                  icon: Icons.search_rounded,
                  label: "Search City",
                  loading: _searchLoading,
                  delay: 400,
                  color: Colors.white,
                  textColor: Colors.blue.shade800,
                  onPressed: () async {
                    final city = await Navigator.push<String?>(
                      context,
                      MaterialPageRoute(builder: (_) => const CitySearchScreen()),
                    );
                    if (city != null && city.trim().isNotEmpty) {
                      _loadByCity(city.trim());
                    }
                  },
                ),

                const SizedBox(height: 16),

                _mainButton(
                  icon: Icons.my_location_rounded,
                  label: "Use Current Location",
                  loading: _loading && !_searchLoading,
                  delay: 500,
                  color: Colors.white.withValues(alpha: 0.2),
                  textColor: Colors.white,
                  onPressed: _loadByLocation,
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _smallButton(
                        icon: Icons.location_city_rounded,
                        label: "Saved",
                        delay: 600,
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddLocationScreen()));
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _smallButton(
                        icon: Icons.map_rounded,
                        label: "Map",
                        delay: 650,
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ChooseCityByMapScreen()));
                        },
                      ),
                    ),
                  ],
                ),

                if (_error != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!, style: const TextStyle(color: Colors.white))),
                      ],
                    ),
                  ).animate().shake(),
                ],
              ],
            ),
          ),
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 40),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [

            // ⭐ UPDATED LOGIC: BLOCK GUEST USERS ⭐
            IconButton(
              icon: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;

                if (user != null && user.isAnonymous) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Guest users cannot access personalization. Please log in."),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return; // STOP HERE → DO NOT NAVIGATE
                }

                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
            ),

            Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.3)),

            IconButton(
              icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChatScreen(currentWeather: "No data", weatherData: null),
                ),
              ),
            ),
          ],
        ),
      ).animate().slideY(begin: 1, end: 0, delay: 800.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _mainButton({
    required IconData icon,
    required String label,
    required bool loading,
    required int delay,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        icon: loading
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: textColor, strokeWidth: 2))
            : Icon(icon, color: textColor),
        label: Text(
          loading ? "Processing..." : label,
          style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _smallButton({
    required IconData icon,
    required String label,
    required int delay,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 55,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 20, color: Colors.white),
        label: Text(label, style: const TextStyle(fontSize: 15)),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, end: 0);
  }
}
