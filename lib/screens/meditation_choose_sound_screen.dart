import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MeditationChooseSoundScreen extends StatelessWidget {
  final Function(String) onSelected;

  const MeditationChooseSoundScreen({super.key, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    // Enhanced data structure with specific icons and descriptions
    final List<Map<String, dynamic>> sounds = [
      {
        "name": "rain-sound",
        "label": "Gentle Rain",
        "desc": "Soothing drops for deep focus",
        "icon": Icons.water_drop_outlined
      },
      {
        "name": "waterfall",
        "label": "Waterfall",
        "desc": "Continuous flow for relaxation",
        "icon": Icons.water_outlined
      },
      {
        "name": "fire-sound",
        "label": "Firewood Burning",
        "desc": "Warm crackles for comfort",
        "icon": Icons.local_fire_department_outlined
      },
      {
        "name": "birds",
        "label": "Forest Birds",
        "desc": "Nature's melody for peace",
        "icon": Icons.forest_outlined
      },
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Choose Sound",
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
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: sounds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final sound = sounds[index];
              return _buildSoundCard(context, sound, index);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSoundCard(BuildContext context, Map<String, dynamic> sound, int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            onSelected(sound["name"]!);
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    sound["icon"],
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),

                // Text Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sound["label"],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sound["desc"],
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 18
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: (100 * index).ms)
        .slideX(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}