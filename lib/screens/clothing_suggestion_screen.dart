import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/weather_service.dart';

class ClothingSuggestionScreen extends StatefulWidget {
  const ClothingSuggestionScreen({super.key});

  @override
  State<ClothingSuggestionScreen> createState() =>
      _ClothingSuggestionScreenState();
}

class _ClothingSuggestionScreenState extends State<ClothingSuggestionScreen> {
  String userCity = "--";
  bool loading = true;
  String statusMessage = "Loading user & weather data...";
  Map<String, dynamic>? weather;
  int? ageYears;
  String ageGroup = "Unknown";

  @override
  void initState() {
    super.initState();
    _loadUserAndWeather();
  }

  Future<void> _loadUserAndWeather() async {
    setState(() {
      loading = true;
      statusMessage = "Fetching user profile...";
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        loading = false;
        statusMessage = "Not signed in.";
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final data = doc.data() ?? <String, dynamic>{};

      final cityFromStore = (data["city"] ?? data["userCity"] ?? "").toString();
      final dob = (data["dob"] ?? data["date_of_birth"] ?? "").toString();
      final ageField = data["age"] ?? data["ageYears"];

      if (cityFromStore.trim().isNotEmpty) {
        userCity = cityFromStore;
      }

      if (ageField != null) {
        try {
          ageYears = int.tryParse(ageField.toString());
        } catch (_) {
          ageYears = null;
        }
      }

      if (ageYears == null && dob.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(dob);
        if (parsed != null) {
          final now = DateTime.now();
          int years = now.year - parsed.year;
          if (now.month < parsed.month ||
              (now.month == parsed.month && now.day < parsed.day)) {
            years--;
          }
          ageYears = years;
        }
      }

      ageYears ??= -1;

      setState(() => statusMessage = "Fetching weather for $userCity...");

      if (userCity.trim().isEmpty || userCity == "--") {
        setState(() {
          loading = false;
          statusMessage =
          "No city found in your profile. Please set city first.";
        });
        return;
      }

      weather = await WeatherService().byCity(userCity);
      ageGroup = _computeAgeGroup(ageYears ?? -1);

      setState(() {
        loading = false;
        statusMessage = "Recommendations ready";
      });
    } catch (e) {
      setState(() {
        loading = false;
        statusMessage = "Error loading data: $e";
      });
    }
  }

  String _computeAgeGroup(int age) {
    if (age < 0) return "Unknown";
    if (age >= 1 && age <= 3) return "Newborn (1-3)";
    if (age >= 4 && age <= 10) return "Child (4-10)";
    if (age >= 11 && age <= 19) return "Teen (11-19)";
    if (age >= 20 && age <= 29) return "Adult (20-29)";
    if (age >= 30 && age <= 49) return "Senior Adult (30-49)";
    if (age >= 50 && age <= 60) return "Quinquagenarian (50-60)";
    if (age >= 61 && age <= 70) return "Sexagenarian (61-70)";
    if (age >= 71 && age <= 75) return "Elder (71-75)";
    if (age > 75) return "Aged (75+)";
    return "Unknown";
  }

  Map<String, dynamic> _generateClothingRecommendations() {
    if (weather == null) {
      return {
        "severity": "low",
        "recommendations": <String>[],
        "metrics": <String, dynamic>{}
      };
    }

    // ✅ FIX: Properly cast nested maps
    final main = (weather!["main"] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final wind = (weather!["wind"] as Map<dynamic, dynamic>?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final weatherList = (weather!["weather"] as List?) ?? [];
    final desc = (weatherList.isNotEmpty
        ? (weatherList[0]["description"] ?? "")
        : "")
        .toString()
        .toLowerCase();

    final double temp =
    (main["temp"] is num) ? (main["temp"] as num).toDouble() : 0.0;
    final double feelsLike = (main["feels_like"] is num)
        ? (main["feels_like"] as num).toDouble()
        : temp;
    final double humidity =
    (main["humidity"] is num) ? (main["humidity"] as num).toDouble() : 50.0;
    final double windSpeed =
    (wind["speed"] is num) ? (wind["speed"] as num).toDouble() : 0.0;
    final int visibility = (weather!["visibility"] is int)
        ? (weather!["visibility"] as int)
        : 10000;

    final List<String> rec = [];
    String severity = "low";

    // ---- Core temperature rules
    if (temp >= 38 || feelsLike >= 38) {
      severity = "high";
      rec.add(
          "Very hot — prefer light, breathable cotton clothing and stay hydrated.");
      rec.add("Use a sun hat/cap and sunglasses; avoid peak sun (11am–4pm).");
    } else if (temp >= 29) {
      severity = severity == "high" ? severity : "medium";
      rec.add(
          "Hot weather — T-shirt/shorts or light dress. Breathable fabrics (cotton/linen).");
      rec.add("Carry water; avoid heavy exercise outdoors.");
    } else if (temp >= 20) {
      rec.add(
          "Mild temperature — light layers (shirt + light jacket if evening).");
    } else if (temp >= 10) {
      severity = "medium";
      rec.add("Cool — wear a sweater or light insulated jacket.");
      rec.add("Consider long trousers and closed shoes.");
    } else {
      severity = "high";
      rec.add(
          "Cold — heavy coat, scarf, gloves, warm hat and insulated footwear recommended.");
      rec.add("Layering is important for seniors and children.");
    }

    // ---- Precipitation
    // ---- Precipitation + Umbrella Logic
    if (desc.contains("rain") ||
        desc.contains("drizzle") ||
        desc.contains("shower")) {
      severity = severity == "high" ? severity : "medium";

      rec.add("Rain present — keep an umbrella or raincoat with you.");
      rec.add("Waterproof jacket and water-resistant shoes are recommended.");
      rec.add("Avoid cotton socks/shoes; choose quick-dry materials.");

      // Umbrella specifics
      if (windSpeed > 12) {
        rec.add("Strong winds detected — umbrella may flip. Prefer a hooded raincoat.");
      } else {
        rec.add("Standard umbrella will work fine in this weather.");
      }
    }

    // ---- Extreme Weather
    if (desc.contains("thunder") || desc.contains("storm")) {
      severity = "high";
      rec.add(
          "Thunderstorm — stay indoors; heavy rain and lightning risk. Avoid metal umbrellas.");
    }
    if (desc.contains("snow") || desc.contains("sleet")) {
      severity = "high";
      rec.add(
          "Snow/Sleet — thermal layers, waterproof boots, and traction on soles.");
    }

    // ---- Visibility
    if (visibility < 2000 ||
        desc.contains("fog") ||
        desc.contains("haze") ||
        desc.contains("smoke")) {
      severity = severity == "high" ? severity : "medium";
      rec.add(
          "Low visibility — if traveling, wear reflective clothing and use vehicle fog lights.");
      if (desc.contains("smoke") || desc.contains("haze")) {
        rec.add(
            "Air quality may be poor — consider masks for outdoor activity.");
      }
    }

    // ---- Wind
    if (windSpeed > 8) {
      severity = "medium";
      rec.add("Windy — windbreaker recommended. Secure hats and loose items.");
      if (windSpeed > 20) {
        severity = "high";
        rec.add("Very strong winds — postpone outdoor activities if possible.");
      }
    }

    // ---- Age Specific
    // ---- Age Specific (Dynamic for Summer & Winter)
    final group = ageGroup;

    if (group.startsWith("Newborn") || group.startsWith("Child")) {
      if (temp <= 10) {
        rec.add(
            "For children: add warm layers, cap/hood, gloves. Keep outings short in cold weather.");
      } else if (temp >= 30) {
        rec.add(
            "For children: light cotton clothing, sun hat, and frequent hydration. Avoid peak heat.");
      } else {
        rec.add(
            "For children: comfortable clothing and a light layer if windy or at night.");
      }
    }

// ------- Older adults (50+)
    else if (group.contains("Senior") ||
        group.contains("Quinquagenarian") ||
        group.contains("Sexagenarian") ||
        group.contains("Elder") ||
        group.contains("Aged")) {

      if (temp <= 10) {
        rec.add(
            "Older adults: wear warm layers, thermal innerwear, scarf, warm hat, and non-slip footwear. Cold increases health risks.");
      } else if (temp >= 30) {
        rec.add(
            "Older adults: light, breathable clothing; avoid outdoor activity in heat; stay hydrated and cool.");
      } else {
        rec.add(
            "Older adults: dress comfortably with light layers; ensure proper footwear for stability.");
      }
    }


    return {
      "severity": severity,
      "recommendations": rec,
      "metrics": {
        "temp": temp,
        "feels_like": feelsLike,
        "humidity": humidity,
        "wind": windSpeed,
        "desc": desc,
      }
    };
  }

  Color _severityColor(String s) {
    switch (s) {
      case "high":
        return Colors.redAccent.shade100;
      case "medium":
        return Colors.orangeAccent.shade100;
      default:
        return Colors.lightGreenAccent.shade100;
    }
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _generateClothingRecommendations();
    final recs = result["recommendations"] as List<String>? ?? [];
    final severity = result["severity"] as String? ?? "low";
    final metrics = result["metrics"] as Map<String, dynamic>? ?? {};

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Smart Wardrobe", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade600,
              Colors.blue.shade400,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: loading
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  statusMessage,
                  style: const TextStyle(color: Colors.white70),
                ).animate().shimmer(duration: 1500.ms, curve: Curves.easeInOut),
              ],
            ),
          )
              : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on, color: Colors.white.withValues(alpha: 0.8), size: 20),
                    const SizedBox(width: 4),
                    Text(
                      userCity,
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  "${ageYears != null && ageYears! >= 0 ? '$ageYears years' : 'Age Unknown'} • $ageGroup",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        (metrics['desc'] ?? '').toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMetric(Icons.thermostat, "${(metrics['temp'] ?? 0).round()}°C", "Temp"),
                          _buildMetric(Icons.air, "${metrics['wind'] ?? 0} m/s", "Wind"),
                          _buildMetric(Icons.water_drop, "${(metrics['humidity'] ?? 0).round()}%", "Humidity"),
                        ],
                      ),
                    ],
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 20),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _severityColor(severity).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _severityColor(severity).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          severity == "high" ? Icons.warning_rounded : Icons.check_circle_rounded,
                          color: _severityColor(severity),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "ADVISORY LEVEL: ${severity.toUpperCase()}",
                          style: TextStyle(
                            color: _severityColor(severity),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(),

                const SizedBox(height: 10),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Recommendations",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: recs.isEmpty
                      ? const Center(child: Text("No suggestions available.", style: TextStyle(color: Colors.white70)))
                      : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: recs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.checkroom, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                recs[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 400.ms, delay: (100 * index).ms)
                          .slideY(begin: 0.2, end: 0);
                    },
                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () => _loadUserAndWeather(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade900,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      "Refresh Suggestions",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ).animate().slideY(begin: 1, end: 0, delay: 500.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}