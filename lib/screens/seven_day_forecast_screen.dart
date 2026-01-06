import 'package:flutter/material.dart';

class SevenDayForecastScreen extends StatelessWidget {
  final List<Map<String, dynamic>> forecast;

  const SevenDayForecastScreen({super.key, required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allows gradient to cover the top
      appBar: AppBar(
        title: const Text(
            "7 Day Forecast",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        // 1. Global Gradient Background
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
          child: forecast.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: forecast.length,
            itemBuilder: (context, index) {
              final dayData = forecast[index];

              // 2. Staggered Animation Wrapper
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                // Slight delay effect based on index (simulated stagger)
                duration: Duration(milliseconds: 400 + (index * 100)),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)), // Slide up
                    child: Opacity(
                      opacity: value, // Fade in
                      child: _buildForecastCard(dayData),
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

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 60, color: Colors.white54),
          SizedBox(height: 10),
          Text(
            "No forecast data available",
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastCard(Map<String, dynamic> data) {
    // 3. Safe Data Extraction
    final icon = data['icon']?.toString() ?? "⛅";
    final day = data['day']?.toString() ?? "Unknown";
    final wind = data['wind']?.toString() ?? "--";
    final temp = data['temp']?.toString() ?? "--";
    final minTemp = data['min_temp']?.toString() ?? "--";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        // Glassmorphism effect
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Side: Day and Wind
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.air, color: Colors.white60, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "$wind km/h",
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Center: Weather Icon
            Text(
              icon,
              style: const TextStyle(fontSize: 32),
            ),

            // Right Side: Temperatures
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "$temp°",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$minTemp°",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}