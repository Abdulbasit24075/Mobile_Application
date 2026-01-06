import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/weather_service.dart';

class UserAlertsScreen extends StatefulWidget {
  const UserAlertsScreen({super.key});

  @override
  State<UserAlertsScreen> createState() => _UserAlertsScreenState();
}

class _UserAlertsScreenState extends State<UserAlertsScreen> {
  String userCity = "--";
  bool loading = true;
  Map<String, dynamic>? weather;

  @override
  void initState() {
    super.initState();
    _loadCityAndWeather();
  }

  Future<void> _loadCityAndWeather() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (mounted) {
        setState(() {
          userCity = doc.data()?["city"] ?? "--";
        });
      }

      final fetchedWeather = await WeatherService().byCity(userCity);
      print("API Temperature: ${fetchedWeather["main"]?["temp"]}");
      print("API City: $userCity");
      print("Full API Data: $fetchedWeather");

      if (mounted) {
        setState(() {
          weather = fetchedWeather;
          loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => loading = false);
      debugPrint("Error loading weather: $e");
    }
  }

  // ===========================================================
  // ⭐ Enhanced & Safer Alert Generator
  // ===========================================================
  List<Map<String, dynamic>> _generateAlerts() {
    if (weather == null) return [];

    // Safe extraction with fallbacks
    final main = weather?["main"] ?? {};
    final wind = weather?["wind"] ?? {};
    final weatherList = weather?["weather"] as List?;
    final desc = (weatherList != null && weatherList.isNotEmpty)
        ? (weatherList[0]["description"] ?? "").toString().toLowerCase()
        : "";

    // Parse values safely
    double temp = double.tryParse(main["temp"]?.toString() ?? "0") ?? 0.0;
    double windSpeed = double.tryParse(wind["speed"]?.toString() ?? "0") ?? 0.0;
    int vis = int.tryParse(weather?["visibility"]?.toString() ?? "10000") ?? 10000;

    List<Map<String, dynamic>> alerts = [];

    // 🌡 TEMPERATURE WARNINGS
    if (temp > 36) {
      alerts.add({
        "icon": "🔥",
        "severity": "High",
        "title": "Extreme Heat",
        "tips": [
          "Avoid going outside 12 PM – 5 PM",
          "Increase water intake significantly",
          "Wear loose, light-colored clothes",
          "Watch for heatstroke symptoms",
        ],
      });
    } else if (temp > 29) {
      alerts.add({
        "icon": "☀️",
        "severity": "Medium",
        "title": "Hot Weather",
        "tips": [
          "Use sunscreen",
          "Drink at least 3 liters of water",
          "Limit direct sun exposure",
        ],
      });
    } else if (temp < 10) {
      alerts.add({
        "icon": "❄️",
        "severity": "Medium",
        "title": "Cold Weather Alert",
        "tips": [
          "Wear warm layers (thermals)",
          "Cover head, ears, and hands",
          "Limit time outdoors",
        ],
      });
    }

    // 🌫 SMOKE / HAZE / POLLUTION
    if (desc.contains("smoke") || desc.contains("haze")) {
      alerts.add({
        "icon": "🌫️",
        "severity": "High",
        "title": "Poor Air Quality",
        "tips": [
          "Wear a high-quality mask (N95)",
          "Avoid outdoor cardio",
          "Use air purifiers indoors",
        ],
      });
    }

    // 🌧 RAIN & THUNDER
    if (desc.contains("rain") || desc.contains("drizzle")) {
      alerts.add({
        "icon": "🌧️",
        "severity": "Medium",
        "title": "Rain Expected",
        "tips": [
          "Carry an umbrella/raincoat",
          "Drive slowly – wet roads are slippery",
          "Avoid low-lying flood areas",
        ],
      });
    }

    if (desc.contains("thunder")) {
      alerts.add({
        "icon": "⛈️",
        "severity": "High",
        "title": "Thunderstorm Warning",
        "tips": [
          "Stay indoors immediately",
          "Unplug sensitive electronics",
          "Avoid open fields and tall trees",
        ],
      });
    }

    // 💨 WIND
    if (windSpeed > 4) {
      alerts.add({
        "icon": "💨",
        "severity": "Medium",
        "title": "Strong Winds",
        "tips": [
          "Secure outdoor furniture",
          "Watch for falling branches",
          "Avoid walking near construction sites",
        ],
      });
    }

    // 👁 LOW VISIBILITY
    if ((vis < 2000)||desc.contains("fog")) {
      alerts.add({
        "icon": "👓",
        "severity": "Medium",
        "title": "Low Visibility",
        "tips": [
          "Use fog lights while driving",
          "Keep safe distance from other vehicles",
          "Avoid highway travel if possible",
        ],
      });
    }

    // 🌍 TRAVEL SAFETY
    if (desc.contains("rain") ||
        desc.contains("snow")||desc.contains("overcast cloud") ||
        windSpeed > 9 ||
        vis < 3000) {
      alerts.add({
        "icon": "✈️",
        "severity": "Medium",
        "title": "Travel Advisory",
        "tips": [
          "Check flight/transit schedules",
          "Expect delays",
          "Keep documents in waterproof bags",
        ],
      });
    }

    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _generateAlerts();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Alerts for $userCity",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : alerts.isEmpty
              ? _buildSafeState()
              : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: alerts.length + 1, // +1 for the header text
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    "Based on real-time weather conditions, here are your safety alerts:",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 16,
                    ),
                  ),
                );
              }

              final alert = alerts[index - 1];

              // Staggered Animation
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 400 + (index * 150)),
                curve: Curves.easeOutQuart,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)), // Slide Up
                    child: Opacity(
                      opacity: value, // Fade In
                      child: _buildAlertCard(alert),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSafeState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.greenAccent),
          const SizedBox(height: 20),
          const Text(
            "No Active Alerts",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "The weather in $userCity is currently safe.",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final isHighSeverity = alert['severity'] == "High";
    final severityColor = isHighSeverity ? Colors.redAccent : Colors.orangeAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHighSeverity
              ? Colors.redAccent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                alert['icon'],
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert['title'],
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${alert['severity']} Severity",
                        style: TextStyle(
                          fontSize: 12,
                          color: severityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          ...alert["tips"].map<Widget>((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("• ", style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: Text(
                    tip,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}