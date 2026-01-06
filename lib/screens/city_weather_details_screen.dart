import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'weather_relax_sound_screen.dart';

class CityWeatherDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const CityWeatherDetailsScreen({super.key, required this.weatherData});

  String _formatTime(int? timestamp) {
    if (timestamp == null) return "--";
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true).toLocal();
    return DateFormat('hh:mm a').format(dt);
  }

  String _windDirection(num? degree) {
    if (degree == null) return "--";
    const directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
    return directions[((degree + 22.5) ~/ 45) % 8];
  }

  Widget _detailTile(String icon, String title, String value, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (100 * index).ms)
        .slideX(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
  }

  @override
  Widget build(BuildContext context) {
    final main = weatherData["main"] ?? {};
    final wind = weatherData["wind"] ?? {};
    final clouds = weatherData["clouds"] ?? {};
    final coord = weatherData["coord"] ?? {};
    final sys = weatherData["sys"] ?? {};

    // ⭐ 1. Check for Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ⭐ 2. Define Gradients (Day vs Night)
    final gradientColors = isDark
        ? [const Color(0xFF1A233A), const Color(0xFF151925)] // Dark Mode (Deep Navy/Black)
        : [
      Colors.blue.shade900,
      Colors.blue.shade600,
      Colors.blue.shade400,
    ]; // Light Mode (Blue)

    // Prepare list of details to render dynamically
    final details = [
      {"icon": "🌡️", "title": "Feels Like", "value": "${main['feels_like']?.toStringAsFixed(1) ?? '--'}°C"},
      {"icon": "⬇️", "title": "Min Temp", "value": "${main['temp_min']?.toStringAsFixed(1) ?? '--'}°C"},
      {"icon": "⬆️", "title": "Max Temp", "value": "${main['temp_max']?.toStringAsFixed(1) ?? '--'}°C"},
      {"icon": "💧", "title": "Humidity", "value": "${main['humidity'] ?? '--'} %"},
      {"icon": "📦", "title": "Pressure", "value": "${main['pressure'] ?? '--'} hPa"},
      {"icon": "💨", "title": "Wind Speed", "value": "${wind['speed'] ?? '--'} m/s"},
      {"icon": "🧭", "title": "Wind Dir", "value": _windDirection(wind['deg'])},
      {"icon": "☁️", "title": "Cloudiness", "value": "${clouds['all'] ?? '--'} %"},
      {"icon": "👁️", "title": "Visibility", "value": "${(weatherData['visibility'] ?? 0) / 1000} km"},
      {"icon": "🌅", "title": "Sunrise", "value": _formatTime(sys['sunrise'])},
      {"icon": "🌇", "title": "Sunset", "value": _formatTime(sys['sunset'])},
      {"icon": "📍", "title": "Coordinates", "value": "${coord['lat']}, ${coord['lon']}"},
    ];

    if (main.containsKey('sea_level')) {
      details.add({"icon": "🌊", "title": "Sea Level", "value": "${main['sea_level']} hPa"});
    }
    if (main.containsKey('grnd_level')) {
      details.add({"icon": "🏔️", "title": "Ground Level", "value": "${main['grnd_level']} hPa"});
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
        title: const Text(
          "Detailed Report",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          // ⭐ 3. Apply Dynamic Gradient
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  children: [
                    // Animated Header Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                        ),
                        child: const Icon(Icons.analytics_outlined, size: 40, color: Colors.white),
                      )
                          .animate()
                          .scale(duration: 500.ms, curve: Curves.elasticOut)
                          .fade(duration: 400.ms),
                    ),

                    // Generate list of detail tiles
                    ...details.asMap().entries.map((entry) {
                      return _detailTile(
                        entry.value['icon']!,
                        entry.value['title']!,
                        entry.value['value']!,
                        entry.key,
                      );
                    }),

                    const SizedBox(height: 30),

                    // Relax Sound Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade800,
                          elevation: 4,
                          shadowColor: Colors.black.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.headphones, size: 24),
                        label: const Text(
                          "Relaxing Weather Sounds",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => WeatherRelaxSoundScreen(weatherData: weatherData),
                            ),
                          );
                        },
                      ),
                    )
                        .animate()
                        .slideY(begin: 0.5, end: 0, delay: 500.ms, duration: 500.ms, curve: Curves.easeOutBack)
                        .fade(delay: 500.ms),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}