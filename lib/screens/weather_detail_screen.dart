import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'chat_screen.dart';
import '../services/weather_service.dart';
import 'seven_day_forecast_screen.dart';
import 'city_weather_details_screen.dart';
import 'hourly_weather_screen.dart';

class WeatherDetailScreen extends StatelessWidget {
  final Map<String, dynamic> weatherData;

  const WeatherDetailScreen({super.key, required this.weatherData});

  String _formatTemp(num? t) => t == null ? '--' : '${t.toStringAsFixed(0)}°';

  String _flagEmoji(String code) {
    if (code.isEmpty) return '';
    try {
      return code.toUpperCase().runes
          .map((c) => String.fromCharCode(c + 127397))
          .join();
    } catch (_) {
      return "";
    }
  }

  String _getWeatherEmoji(String code) {
    const icons = {
      '01d': '☀️', '01n': '🌙', '02d': '⛅', '02n': '☁️',
      '03d': '☁️', '03n': '☁️', '04d': '☁️', '04n': '☁️',
      '09d': '🌧️', '09n': '🌧️', '10d': '🌦️', '10n': '🌦️',
      '11d': '⛈️', '11n': '⛈️', '13d': '❄️', '13n': '❄️',
      '50d': '🌫️', '50n': '🌫️',
    };
    return icons[code] ?? '🌈';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? [const Color(0xFF1A233A), const Color(0xFF151925)]
        : [Colors.blue.shade900, Colors.blue.shade600, Colors.blue.shade400];

    final main = weatherData['main'] ?? {};
    final sys = weatherData['sys'] ?? {};
    final weatherList = weatherData['weather'] as List?;
    final weather = (weatherList != null && weatherList.isNotEmpty)
        ? weatherList[0]
        : {'description': 'Unknown', 'icon': ''};
    final coord = weatherData['coord'];

    final temp = _formatTemp(main['temp']);
    final desc = weather['description'];
    final iconCode = weather['icon'];
    final emoji = _getWeatherEmoji(iconCode);

    final city = weatherData['name'] ?? "Unknown";
    final country = sys['country'] ?? "";
    final flag = _flagEmoji(country);

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
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade800,
        tooltip: "Chat with WeatherWhiz",
        child: const Icon(Icons.chat_bubble_rounded),
        onPressed: () {
          final weatherContext = 'Location: $city, Temp: $temp, Condition: $desc';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(currentWeather: weatherContext, weatherData: weatherData),
            ),
          );
        },
      ).animate().scale(delay: 500.ms, curve: Curves.elasticOut),

      body: Container(
        decoration: BoxDecoration(
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
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(flag, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 10),
                            Text(
                              city,
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                            ),
                          ],
                        ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.5, end: 0),

                        const SizedBox(height: 30),

                        Column(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 110))
                                .animate().scale(duration: 600.ms, curve: Curves.elasticOut)
                                .then().shimmer(duration: 1500.ms, delay: 2000.ms),

                            const SizedBox(height: 10),

                            Text(
                              temp,
                              style: const TextStyle(fontSize: 80, color: Colors.white, fontWeight: FontWeight.w200, height: 1),
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                            Text(
                              desc.toString().toUpperCase(),
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 18, letterSpacing: 2, fontWeight: FontWeight.w500),
                            ).animate().fadeIn(delay: 300.ms),
                          ],
                        ),

                        const SizedBox(height: 50),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: _infoCard(Icons.water_drop_outlined, "Humidity", "${main['humidity']}%", 400)),
                            const SizedBox(width: 12),
                            Expanded(child: _infoCard(Icons.speed, "Pressure", "${main['pressure']} hPa", 500)),
                            const SizedBox(width: 12),
                            Expanded(child: _infoCard(Icons.air, "Wind", "${weatherData['wind']?['speed']} m/s", 600)),
                          ],
                        ),

                        const SizedBox(height: 50),

                        _buildActionButton(
                          icon: Icons.access_time_rounded,
                          label: "View 8-Hour Forecast",
                          delay: 650,
                          onPressed: () {
                            final hourly = WeatherService().generateEightHourForecast(weatherData);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => HourlyWeatherScreen(hourly: hourly)));
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildActionButton(
                          icon: Icons.calendar_today_rounded,
                          label: "View 7-Day Forecast",
                          delay: 700,
                          onPressed: () async {
                            final forecast = WeatherService().generateSevenDayForecast(weatherData);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => SevenDayForecastScreen(forecast: forecast)));
                          },
                        ),

                        const SizedBox(height: 16),

                        _buildActionButton(
                          icon: Icons.analytics_outlined,
                          label: "View City Details",
                          delay: 800,
                          isPrimary: false,
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => CityWeatherDetailsScreen(weatherData: weatherData)));
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value, int delay) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
        ],
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onPressed, required int delay, bool isPrimary = true}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.white : Colors.white.withValues(alpha: 0.15),
          foregroundColor: isPrimary ? Colors.blue.shade900 : Colors.white,
          elevation: isPrimary ? 4 : 0,
          shadowColor: Colors.black.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary ? BorderSide.none : BorderSide(color: Colors.white.withValues(alpha: 0.3)),
          ),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        onPressed: onPressed,
      ),
    ).animate().fadeIn(delay: delay.ms).slideY(begin: 0.5, end: 0, curve: Curves.easeOutBack);
  }
}