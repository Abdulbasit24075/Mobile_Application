import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart'; // Ensure geolocator is imported

import '../services/weather_service.dart';
import 'weather_detail_screen.dart';

class ChooseCityByMapScreen extends StatefulWidget {
  const ChooseCityByMapScreen({super.key});

  @override
  State<ChooseCityByMapScreen> createState() => _ChooseCityByMapScreenState();
}

class _ChooseCityByMapScreenState extends State<ChooseCityByMapScreen> {
  final MapController _mapController = MapController();
  LatLng? tappedPoint;
  String locationName = "Tap any location";
  bool loadingName = false;
  final WeatherService _svc = WeatherService();

  Future<void> _reverseGeocode(LatLng latlng) async {
    setState(() {
      loadingName = true;
      locationName = "Identifying location...";
    });

    final url =
        "https://nominatim.openstreetmap.org/reverse?format=json&lat=${latlng.latitude}&lon=${latlng.longitude}&zoom=10&addressdetails=1";

    try {
      final res = await http.get(Uri.parse(url),
          headers: {"User-Agent": "WeatherWhiz-App"});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final address = data["address"] ?? {};

        locationName = address["city"] ??
            address["town"] ??
            address["village"] ??
            address["state"] ??
            "Unknown location";
      } else {
        locationName = "Unknown Area";
      }
    } catch (e) {
      locationName = "Unknown Area";
    }

    if (mounted) setState(() => loadingName = false);
  }

  Future<void> _loadWeather() async {
    if (tappedPoint == null) return;

    try {
      // Use coordinates directly for better accuracy
      final data = await _svc.byCoords(
        tappedPoint!.latitude,
        tappedPoint!.longitude,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WeatherDetailScreen(weatherData: data),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unable to load weather for this location")),
      );
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      // Request permission if needed
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );

      Position position = await Geolocator.getCurrentPosition(locationSettings: locationSettings);
      final latLng = LatLng(position.latitude, position.longitude);

      _mapController.move(latLng, 13);
      setState(() => tappedPoint = latLng);
      _reverseGeocode(latLng);

    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue.shade800,
        onPressed: _goToCurrentLocation,
        child: const Icon(Icons.my_location),
      ).animate().scale(delay: 300.ms, curve: Curves.easeOutBack),

      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(31.5204, 74.3587), // Lahore default
              initialZoom: 10,
              onTap: (tapPos, latlng) {
                setState(() {
                  tappedPoint = latlng;
                });
                _reverseGeocode(latlng);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                userAgentPackageName: "com.example.weather_app",
              ),
              if (tappedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: tappedPoint!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 50,
                      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut).then().moveY(begin: 0, end: -10, duration: 600.ms, curve: Curves.easeInOut, ).then().moveY(begin: -10, end: 0, duration: 600.ms, curve: Curves.easeInOut), // Bounce effect
                    )
                  ],
                )
            ],
          ),

          // Bottom Info Panel (Animated Slide-up)
          if (tappedPoint != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75), // Glass dark background
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.place, color: Colors.blueAccent, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                loadingName ? "Identifying..." : locationName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${tappedPoint!.latitude.toStringAsFixed(4)}, ${tappedPoint!.longitude.toStringAsFixed(4)}",
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: loadingName ? null : _loadWeather,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Check Weather Here",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
            ),

          // Helper Text when no point selected
          if (tappedPoint == null)
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    "Tap anywhere on the map",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: -1, end: 0),
              ),
            ),
        ],
      ),
    );
  }
}