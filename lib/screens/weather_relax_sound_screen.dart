import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

class WeatherRelaxSoundScreen extends StatefulWidget {
  final Map<String, dynamic> weatherData;

  const WeatherRelaxSoundScreen({super.key, required this.weatherData});

  @override
  State<WeatherRelaxSoundScreen> createState() =>
      _WeatherRelaxSoundScreenState();
}

class _WeatherRelaxSoundScreenState extends State<WeatherRelaxSoundScreen> {
  final AudioPlayer _player = AudioPlayer();

  String selectedSound = "";
  String soundTitle = "";
  bool isPlaying = false;

  /// 🔥 Timer Variables
  Duration _selectedTimerDuration = const Duration(minutes: 5);
  Duration _countdown = Duration.zero;
  Timer? _timer;

  // Define available sounds with metadata
  final List<Map<String, dynamic>> soundLibrary = [
    {"id": "rain-sound", "title": "Gentle Rain", "icon": Icons.water_drop},
    {"id": "waterfall", "title": "Waterfall Flow", "icon": Icons.water},
    {"id": "fire-sound", "title": "Cozy Fireplace", "icon": Icons.local_fire_department},
    {"id": "birds", "title": "Forest Birds", "icon": Icons.forest},
  ];

  @override
  void initState() {
    super.initState();
    _autoSelectSound();
  }

  void _autoSelectSound() {
    final weather = widget.weatherData["weather"][0]["description"]
        .toString()
        .toLowerCase();
    final temp = widget.weatherData["main"]["temp"]?.toDouble() ?? 25.0;
    final wind = widget.weatherData["wind"]["speed"]?.toDouble() ?? 0.0;

    String id = "birds";
    if (weather.contains("rain")) {
      id = "rain-sound";
    } else if (wind > 10) id = "birds";
    else if (temp < 12) id = "fire-sound";
    else if (temp > 32) id = "waterfall";

    final sound = soundLibrary.firstWhere(
            (s) => s['id'] == id,
        orElse: () => soundLibrary.last);

    setState(() {
      selectedSound = "assets/sounds/${sound['id']}.mp3";
      soundTitle = sound['title'];
    });
  }

  Future<void> _toggleSound() async {
    if (!isPlaying) {
      final path = selectedSound.replaceFirst("assets/", "");
      await _player.play(AssetSource(path));
      await _player.setReleaseMode(ReleaseMode.loop);

      /// Start Timer
      _countdown = _selectedTimerDuration;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;

        if (_countdown.inSeconds <= 0) {
          _stopSoundDueToTimer();
        } else {
          setState(() {
            _countdown -= const Duration(seconds: 1);
          });
        }
      });
    } else {
      _stopPlayback();
    }

    setState(() => isPlaying = !isPlaying);
  }

  void _stopPlayback() {
    _timer?.cancel();
    _player.pause();

    setState(() {
      isPlaying = false;
      _countdown = Duration.zero;
    });
  }

  void _stopSoundDueToTimer() {
    _timer?.cancel();
    _player.stop();

    setState(() {
      isPlaying = false;
      _countdown = Duration.zero;
    });
  }

  void _changeSound(Map<String, dynamic> sound) async {
    final newPath = "assets/sounds/${sound['id']}.mp3";
    if (newPath == selectedSound) return;

    setState(() {
      selectedSound = newPath;
      soundTitle = sound['title'];
      isPlaying = true;
    });

    _timer?.cancel();

    _player.stop();
    final path = selectedSound.replaceFirst("assets/", "");
    await _player.play(AssetSource(path));
    await _player.setReleaseMode(ReleaseMode.loop);

    /// Restart Timer
    _countdown = _selectedTimerDuration;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_countdown.inSeconds <= 0) {
        _stopSoundDueToTimer();
      } else {
        setState(() {
          _countdown -= const Duration(seconds: 1);
        });
      }
    });
  }

  /// 🔥 Timer Picker Dialog (1 to 20 minutes)
  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("Select Timer Duration",
            style: TextStyle(color: Colors.white)),
        content: SizedBox(
          height: 300,
          width: 200,
          child: ListView.builder(
            itemCount: 20,
            itemBuilder: (context, index) {
              final min = index + 1;
              return ListTile(
                title: Text("$min minutes",
                    style: const TextStyle(color: Colors.white)),
                onTap: () {
                  setState(() {
                    _selectedTimerDuration = Duration(minutes: min);
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final city = widget.weatherData["name"] ?? "Unknown City";
    final desc = widget.weatherData["weather"][0]["description"] ?? "";
    final iconCode = widget.weatherData["weather"][0]["icon"] ?? "01d";

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
        title: const Text("Soundscape",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),

      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade900,
              Colors.purple.shade900,
              Colors.deepPurple.shade900,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Weather chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(
                      "https://openweathermap.org/img/wn/$iconCode.png",
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "$city • $desc",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.5, end: 0),

              const Spacer(),

              // Pulsing Circle
              Stack(
                alignment: Alignment.center,
                children: [
                  if (isPlaying)
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.2, 1.2),
                        duration: 1500.ms),
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.purple.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      isPlaying ? Icons.music_note_rounded : Icons.headphones,
                      size: 80,
                      color: Colors.white,
                    ),
                  ).animate(target: isPlaying ? 1 : 0)
                      .shimmer(duration: 2000.ms,
                      color: Colors.white.withValues(alpha: 0.5)),
                ],
              ),

              const SizedBox(height: 40),

              Text(
                soundTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ).animate().fadeIn(delay: 200.ms),

              Text(
                isPlaying
                    ? "Now Playing • ${_countdown.inMinutes}:${(_countdown.inSeconds % 60).toString().padLeft(2, '0')}"
                    : "Paused",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: _toggleSound,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 40,
                    color: Colors.deepPurple.shade900,
                  ),
                ),
              ).animate().scale(delay: 400.ms, curve: Curves.elasticOut),

              const Spacer(),

              // Sound selector
              Container(
                height: 140,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border(
                      top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  scrollDirection: Axis.horizontal,
                  itemCount: soundLibrary.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final sound = soundLibrary[index];
                    final isSelected = selectedSound.contains(sound['id']);

                    return GestureDetector(
                      onTap: () => _changeSound(sound),
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? null
                              : Border.all(
                              color:
                              Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              sound['icon'],
                              color:
                              isSelected ? Colors.purple.shade900 : Colors.white,
                              size: 28,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              sound['title'].split(' ')[0],
                              style: TextStyle(
                                color:
                                isSelected ? Colors.purple.shade900 : Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (500 + (index * 100)).ms).slideX();
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      /// ⭐ TIMER BUTTON AT TOP-RIGHT
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: _showTimerDialog,
        child: const Icon(Icons.timer, color: Colors.deepPurple),
      ),
    );
  }
}
