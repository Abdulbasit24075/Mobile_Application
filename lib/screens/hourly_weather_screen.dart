import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Ensure this is in pubspec.yaml

class HourlyWeatherScreen extends StatelessWidget {
  final List<Map<String, dynamic>> hourly;

  const HourlyWeatherScreen({super.key, required this.hourly});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "8-Hour Forecast",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
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
          child: hourly.isEmpty
              ? const Center(
            child: Text(
              "No hourly data available",
              style: TextStyle(color: Colors.white70),
            ),
          )
              : ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: hourly.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final h = hourly[index];
              return _buildHourlyCard(h, index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHourlyCard(Map<String, dynamic> h, int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // --- Left: Time & Icon ---
          Column(
            children: [
              Text(
                h["time"].toString(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                h["icon"].toString(),
                style: const TextStyle(fontSize: 32),
              ),
            ],
          ),

          // --- Vertical Divider ---
          Container(
            height: 50,
            width: 1,
            color: Colors.white.withValues(alpha: 0.2),
          ),

          // --- Right: Details & Temp ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _detailItem(Icons.water_drop_outlined, "${h["humidity"]}%"),
                      Text(
                        "${h["temp"]}°",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _detailItem(Icons.air, "${h["wind"]} m/s"),
                      const SizedBox(width: 16),
                      _detailItem(Icons.speed, "${h["pressure"]} hPa"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (100 * index).ms)
        .slideX(begin: 0.2, end: 0, curve: Curves.easeOut);
  }

  Widget _detailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}