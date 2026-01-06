// language: dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MeditationFormScreen extends StatefulWidget {
  // Accept async callbacks (Future-returning) so passing async save functions compiles cleanly
  final Future<void> Function(String) onResult;

  const MeditationFormScreen({super.key, required this.onResult});

  @override
  State<MeditationFormScreen> createState() => _MeditationFormScreenState();
}

class _MeditationFormScreenState extends State<MeditationFormScreen> {
  String? weather;
  String? mood;

  // Enhanced data with Icons
  final List<Map<String, dynamic>> weatherOptions = [
    {"label": "Rainy", "val": "Rainy", "icon": Icons.water_drop},
    {"label": "Cloudy", "val": "Cloudy", "icon": Icons.cloud},
    {"label": "Sunny / Hot", "val": "Sunny / Hot", "icon": Icons.wb_sunny},
    {"label": "Cold", "val": "Cold", "icon": Icons.ac_unit},
    {"label": "Morning Calm", "val": "Morning Calm", "icon": Icons.wb_twilight},
  ];

  final List<Map<String, dynamic>> moodOptions = [
    {"label": "Sad", "val": "Sad", "icon": Icons.sentiment_dissatisfied},
    {"label": "Tired", "val": "Tired", "icon": Icons.battery_alert},
    {"label": "Stressed", "val": "Stressed", "icon": Icons.psychology},
    {"label": "Fresh", "val": "Fresh", "icon": Icons.sentiment_very_satisfied},
    {"label": "Relax Needed", "val": "Relax Needed", "icon": Icons.spa},
  ];

  String _getMeditationRecommendation() {
    if (weather == "Rainy" || mood == "Sad") return "rain-sound";
    if (weather == "Cloudy" && mood == "Tired") return "rain-sound";
    if (weather == "Sunny / Hot" && mood == "Stressed") return "waterfall";
    if (weather == "Cold" && mood == "Relax Needed") return "fire-sound";
    if (weather == "Morning Calm" || mood == "Fresh") return "birds";
    return "waterfall"; // default
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Personalize", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade400,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "How are you feeling?",
                  style: TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold
                  ),
                ).animate().fadeIn().slideX(),

                const SizedBox(height: 8),

                Text(
                  "We'll suggest the perfect sound for you.",
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.8)
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(),

                const SizedBox(height: 40),

                // Weather Dropdown
                _buildGlassDropdown(
                  label: "Weather Condition",
                  value: weather,
                  items: weatherOptions,
                  onChanged: (val) => setState(() => weather = val),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 20),

                // Mood Dropdown
                _buildGlassDropdown(
                  label: "Your Mood",
                  value: mood,
                  items: moodOptions,
                  onChanged: (val) => setState(() => mood = val),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),

                const Spacer(),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (weather == null || mood == null)
                        ? null
                        : () async {
                      final sound = _getMeditationRecommendation();
                      await widget.onResult(sound);
                      if (mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade900,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.3),
                    ),
                    child: const Text(
                      "Find My Meditation",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms).scale(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDropdown({
    required String label,
    required String? value,
    required List<Map<String, dynamic>> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                "Select...",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              ),
              dropdownColor: Colors.blue.shade800, // Popup background color
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: items.map((item) {
                final labelText = item['label']?.toString() ?? '';
                final iconData = item['icon'] as IconData?;
                final val = item['val']?.toString();
                return DropdownMenuItem<String>(
                  value: val,
                  child: Row(
                    children: [
                      Icon(iconData, color: Colors.white70, size: 20),
                      const SizedBox(width: 12),
                      Text(labelText),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
