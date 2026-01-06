import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/weather_service.dart';
import 'weather_detail_screen.dart';
import 'city_search_screen.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  List<String> savedCities = [];
  bool loading = true;

  Map<String, Map<String, dynamic>> cityWeatherCache = {};
  final WeatherService _svc = WeatherService();

  @override
  void initState() {
    super.initState();
    _loadSavedCities();
  }

  Future<void> _loadSavedCities() async {
    final prefs = await SharedPreferences.getInstance();
    savedCities = prefs.getStringList("saved_cities") ?? [];

    for (final city in savedCities) {
      cityWeatherCache[city] = {};
      _loadWeatherForCity(city);
    }

    if (mounted) setState(() => loading = false);
  }

  Future<void> _loadWeatherForCity(String city) async {
    try {
      final data = await _svc.byCity(city);
      if (mounted) {
        setState(() {
          cityWeatherCache[city] = data;
        });
      }
    } catch (e) {
      debugPrint("Error loading $city: $e");
    }
  }

  Future<void> _saveCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    if (!savedCities.contains(city)) {
      setState(() {
        savedCities.add(city);
        cityWeatherCache[city] = {};
      });
      await prefs.setStringList("saved_cities", savedCities);
      _loadWeatherForCity(city);
    }
  }

  Future<void> _deleteCity(String city) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedCities.remove(city);
      cityWeatherCache.remove(city);
    });
    await prefs.setStringList("saved_cities", savedCities);
  }

  Future<void> _openCityWeather(String city) async {
    try {
      final data = await _svc.byCity(city);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WeatherDetailScreen(weatherData: data),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to load weather.")),
      );
    }
  }

  Future<void> _addNewCity() async {
    final city = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const CitySearchScreen()),
    );

    if (city != null && city.trim().isNotEmpty) {
      await _saveCity(city.trim());
    }
  }

  String _emojiFromIcon(String? icon) {
    if (icon == null) return "🌤️";
    const map = {
      "01d": "☀️", "01n": "🌙",
      "02d": "⛅", "02n": "☁️",
      "03d": "☁️", "03n": "☁️",
      "04d": "☁️", "04n": "☁️",
      "09d": "🌧️", "09n": "🌧️",
      "10d": "🌦️", "10n": "🌦️",
      "11d": "⛈️", "11n": "⛈️",
      "13d": "❄️", "13n": "❄️",
      "50d": "🌫️", "50n": "🌫️",
    };
    return map[icon] ?? "🌤️";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade800,
        onPressed: _addNewCity,
        tooltip: "Add Location",
        child: const Icon(Icons.add),
      ).animate().scale(delay: 500.ms, duration: 400.ms, curve: Curves.easeOutBack),

      body: Container(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "My Locations",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ).animate().fade(duration: 400.ms).slideX(begin: 0.2),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Content
              Expanded(
                child: loading
                    ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
                    : savedCities.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off_outlined,
                          size: 64, color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(
                        "No saved locations yet.\nTap + to add one.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ).animate().fade().scale(),
                )
                    : GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: savedCities.length,
                  itemBuilder: (context, index) {
                    final city = savedCities[index];
                    final data = cityWeatherCache[city] ?? {};

                    final temp =
                        data["main"]?["temp"]?.round().toString() ?? "--";
                    final sys = data["sys"] ?? {};
                    final country = sys["country"] ?? "";
                    final weatherList = data["weather"] as List?;
                    final iconCode =
                    weatherList != null && weatherList.isNotEmpty
                        ? weatherList[0]["icon"]
                        : null;
                    final icon = _emojiFromIcon(iconCode);

                    return GestureDetector(
                      onTap: () => _openCityWeather(city),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top Row: Icon + Delete
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  icon,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                GestureDetector(
                                  onTap: () => _deleteCity(city),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(),

                            // City Name
                            Text(
                              city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            // Country
                            Text(
                              country,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Temperature
                            Text(
                              "$temp°",
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                          .animate()
                          .fade(duration: 400.ms, delay: (100 * index).ms) // Staggered Animation
                          .slideY(begin: 0.2, end: 0),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}