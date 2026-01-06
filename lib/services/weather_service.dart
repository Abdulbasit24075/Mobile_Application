import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AppException implements Exception {
  final String code;
  final String message;
  AppException(this.code, this.message);
  @override
  String toString() => '$code: $message';
}

class AppError {
  static AppException network([String? m]) =>
      AppException('network', m ?? 'No internet connection');
  static AppException timeout([String? m]) =>
      AppException('timeout', m ?? 'Request timed out');
  static AppException notFound([String? m]) =>
      AppException('not-found', m ?? 'City not found');
  static AppException badKey([String? m]) =>
      AppException('bad-api-key', m ?? 'Invalid API key');
  static AppException forbidden([String? m]) =>
      AppException('forbidden', m ?? 'Access forbidden');
  static AppException rateLimited([String? m]) =>
      AppException('rate-limit', m ?? 'Too many requests, try again later');
  static AppException server([String? m]) =>
      AppException('server', m ?? 'Server error, try again');
  static AppException location([String? m]) =>
      AppException('location', m ?? 'Location error');
  static AppException parsing([String? m]) =>
      AppException('parsing', m ?? 'Unexpected data format');
  static AppException unknown([String? m]) =>
      AppException('unknown', m ?? 'Something went wrong');
}

class WeatherService {
  final String _base = AppConstants.baseWeatherUrl;
  final String _key = AppConstants.openWeatherApiKey;
  final http.Client _client = http.Client();

  // --- API CALLS ---

  Future<Map<String, dynamic>> byCity(String city,
      {String units = AppConstants.defaultUnits}) async {
    if (city.trim().isEmpty) throw AppError.notFound('City name cannot be empty');
    final uri = Uri.parse('$_base?q=$city&appid=$_key&units=$units');
    return _fetch(uri);
  }

  Future<Map<String, dynamic>> byCoords(double lat, double lon,
      {String units = AppConstants.defaultUnits}) async {
    final uri = Uri.parse('$_base?lat=$lat&lon=$lon&appid=$_key&units=$units');
    return _fetch(uri);
  }

  Future<Map<String, dynamic>> quickCityWeather(String city) async {
    final uri = Uri.parse('$_base?q=$city&appid=$_key&units=metric');
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 6));

      // ✅ FIX 1: Strict type return
      if (res.statusCode != 200) return <String, dynamic>{};

      final json = jsonDecode(res.body);

      // ✅ FIX 2: Strict type check and conversion
      if (json is Map) {
        final data = Map<String, dynamic>.from(json);
        return <String, dynamic>{
          "city": data["name"],
          "country": data["sys"]?["country"],
          "temp": (data["main"]?["temp"] as num?)?.round(),
          "icon": data["weather"]?[0]?["icon"],
        };
      }
      return <String, dynamic>{};
    } catch (e) {
      return <String, dynamic>{};
    }
  }

  // --- FORECAST GENERATORS ---

  // 1. Generate 7-Day Forecast (Simulated based on current data)
  List<Map<String, dynamic>> generateSevenDayForecast(Map<String, dynamic> weatherData) {
    final main = weatherData["main"] ?? {};
    final weatherList = weatherData["weather"] as List?;
    final weather = (weatherList != null && weatherList.isNotEmpty) ? weatherList.first : {};
    final wind = weatherData["wind"] ?? {};

    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    double temp = toDouble(main["temp"]);
    double feelsLike = toDouble(main["feels_like"]);
    double humidity = toDouble(main["humidity"]);
    double pressure = toDouble(main["pressure"]);
    double windSpeed = toDouble(wind["speed"]);

    String desc = (weather["description"] ?? "").toString();
    final rand = Random();

    // Determine Trend
    double trend = 0;
    if (desc.contains("clear") || desc.contains("sun")) trend = 0.6;
    if (desc.contains("cloud")) trend = 0.2;
    if (desc.contains("rain")) trend = -0.8;
    if (desc.contains("storm") || desc.contains("thunder")) trend = -1.5;
    if (desc.contains("snow")) trend = -2.0;

    List<String> weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    int startIndex = DateTime.now().weekday % 7;

    List<Map<String, dynamic>> forecast = [];

    for (int i = 0; i < 7; i++) {
      double dailyNoise = (rand.nextDouble() * 1.5) - 0.75;
      temp += trend + dailyNoise;
      temp = (temp * 0.7 + feelsLike * 0.3);

      humidity += (rand.nextInt(7) - 3);
      humidity = humidity.clamp(25, 100);

      windSpeed += (rand.nextDouble() * 1.2) - 0.6;
      windSpeed = windSpeed < 0 ? 0 : windSpeed;

      pressure += rand.nextInt(8) - 4;

      String icon = _emojiFromStats(temp, humidity, windSpeed, pressure);

      forecast.add({
        "day": weekDays[(startIndex + i) % 7],
        "temp": temp.round(),
        "min_temp": (temp - 5 - rand.nextInt(3)).round(),
        "humidity": humidity.round(),
        "pressure": pressure.round(),
        "wind": windSpeed.toStringAsFixed(1),
        "icon": icon,
      });
    }
    return forecast;
  }

  // 2. Generate 8-Hour Forecast
  List<Map<String, dynamic>> generateEightHourForecast(Map<String, dynamic> data) {
    final main = data["main"];
    final weatherList = data["weather"] as List?;
    final weather = (weatherList != null && weatherList.isNotEmpty) ? weatherList.first : {};

    double currentTemp = (main["temp"] as num).toDouble();
    double humidity = (main["humidity"] as num).toDouble();
    double pressure = (main["pressure"] as num).toDouble();
    double wind = (data["wind"]["speed"] as num).toDouble();

    final desc = weather["description"].toString().toLowerCase();
    final random = Random();

    int offset = data["timezone"] ?? 0;
    DateTime cityNow = DateTime.now().toUtc().add(Duration(seconds: offset));

    List<Map<String, dynamic>> forecast = [];

    for (int i = 0; i < 8; i++) {
      DateTime hour = cityNow.add(Duration(hours: i));
      int hourLocal = hour.hour;
      bool night = hourLocal < 6 || hourLocal >= 18;

      int tempChange = random.nextInt(3) - 1;
      if (night) tempChange -= random.nextInt(2);
      currentTemp += tempChange;

      double humidityChange = random.nextDouble() * 3 - 1.5;
      if (night) humidityChange += random.nextDouble() * 2;
      humidity = (humidity + humidityChange).clamp(25, 100);

      wind = (wind + (random.nextDouble() - 0.5)).clamp(0, 25);
      pressure += random.nextDouble() * 1.5 - 0.7;

      final icon = _emojiFromHourly(currentTemp, humidity, wind, pressure, desc, hourLocal);

      forecast.add({
        "time": "${hourLocal.toString().padLeft(2, '0')}:00",
        "temp": currentTemp.round(),
        "humidity": humidity.round(),
        "pressure": pressure.round(),
        "wind": wind.toStringAsFixed(1),
        "icon": icon,
      });
    }
    return forecast;
  }

  // --- HELPERS ---

  String _emojiFromStats(double temp, double humidity, double wind, double pressure) {
    if (pressure < 1000 && humidity > 85 && wind > 5) return "⛈️";
    if (pressure < 1005 || humidity > 80) return "🌧️";
    if (humidity > 75 && temp < 18) return "🌫️";
    if (temp > 35 && humidity < 35) return "🥵";
    if (temp > 30) return "☀️";
    if (temp < 5 && humidity > 60) return "❄️";
    if (temp < 10) return "🌬️";
    if (wind > 7) return "💨";
    if (humidity < 40 && pressure > 1015) return "☀️";
    if (humidity < 60) return "⛅";
    return "🌤️";
  }

  String _emojiFromHourly(double temp, double humidity, double wind, double pressure, String desc, int hour) {
    if (desc.contains("rain") || humidity > 85) return "🌧️";
    if (desc.contains("storm") || wind > 20) return "⛈️";
    if (desc.contains("snow") || temp < 4) return "❄️";
    if (desc.contains("fog") || humidity > 80) return "🌫️";
    if (pressure < 1000) return "🌦️";
    if (hour >= 20 || hour <= 5) return humidity > 70 ? "☁️" : "🌙";
    if (temp > 32) return "☀️";
    if (temp > 25) return "🌤️";
    if (humidity < 40) return "⛅";
    return "🌤️";
  }

  Future<Map<String, dynamic>> _fetch(Uri uri) async {
    try {
      final res = await _client.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) return _safeJson(res.body);

      switch (res.statusCode) {
        case 401: throw AppError.badKey();
        case 403: throw AppError.forbidden();
        case 404: throw AppError.notFound();
        case 429: throw AppError.rateLimited();
        default:
          if (res.statusCode >= 500) throw AppError.server();
          throw AppError.unknown('HTTP ${res.statusCode}');
      }
    } on SocketException {
      throw AppError.network();
    } on TimeoutException {
      throw AppError.timeout();
    } on FormatException {
      throw AppError.parsing();
    } catch (_) {
      throw AppError.unknown();
    }
  }

  // ⭐ CRITICAL FIX: Safe Type Casting for JSON with validation
  Map<String, dynamic> _safeJson(String body) {
    final json = jsonDecode(body);
    // Explicitly check and cast to Map<String, dynamic>
    if (json is Map) {
      return Map<String, dynamic>.from(json);
    }
    throw AppError.parsing();
  }

  // 1. Get 7-Day Forecast (Open-Meteo)
  Future<List<Map<String, dynamic>>> fetchSevenDayForecast(double lat, double lon) async {
    final String url = "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&daily=weathercode,temperature_2m_max,temperature_2m_min,windspeed_10m_max&timezone=auto";
    try {
      final res = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final daily = json['daily'];
        final List<dynamic> dates = daily['time'];
        final List<dynamic> maxTemps = daily['temperature_2m_max'];
        final List<dynamic> minTemps = daily['temperature_2m_min'];
        final List<dynamic> winds = daily['windspeed_10m_max'];

        List<Map<String, dynamic>> forecast = [];
        for (int i = 0; i < dates.length; i++) {
          forecast.add({
            "day": dates[i].toString().substring(5),
            "temp": (maxTemps[i] as num).round(),
            "min_temp": (minTemps[i] as num).round(),
            "wind": winds[i].toString(),
            "icon": "🌤️",
          });
        }
        return forecast;
      }
      // ✅ FIX: Strict return type
      return <Map<String, dynamic>>[];
    } catch (e) {
      // ✅ FIX: Strict return type
      return <Map<String, dynamic>>[];
    }
  }

  void dispose() => _client.close();
}