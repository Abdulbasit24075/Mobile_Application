import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class WeatherWidgetProvider {
  // Configuration keys
  static const String _locationKey = 'location';
  static const String _temperatureKey = 'temperature';
  static const String _conditionKey = 'condition';
  static const String _iconKey = 'icon';
  static const String _humidityKey = 'humidity';
  static const String _windKey = 'wind';
  static const String _themeKey = 'theme';
  static const String _unitKey = 'unit';
  static const String _cityKey = 'city';

  // Widget configuration
  static Future<Map<String, dynamic>> getConfiguration() async {
    return {
      'city': await HomeWidget.getWidgetData(_cityKey, defaultValue: 'Lahore'),
      'location': await HomeWidget.getWidgetData(_locationKey, defaultValue: 'Lahore'),
      'temperature': await HomeWidget.getWidgetData(_temperatureKey, defaultValue: '25°C'),
      'condition': await HomeWidget.getWidgetData(_conditionKey, defaultValue: 'Sunny'),
      'icon': await HomeWidget.getWidgetData(_iconKey, defaultValue: '☀️'),
      'humidity': await HomeWidget.getWidgetData(_humidityKey, defaultValue: '65%'),
      'wind': await HomeWidget.getWidgetData(_windKey, defaultValue: '10 km/h'),
      'theme': await HomeWidget.getWidgetData(_themeKey, defaultValue: 'light'),
      'unit': await HomeWidget.getWidgetData(_unitKey, defaultValue: 'celsius'),
    };
  }

  static Future<void> configureWidget({
    String city = 'Lahore',
    String location = 'Lahore',
    String temperature = '25°C',
    String condition = 'Sunny',
    String icon = '☀️',
    String humidity = '65%',
    String wind = '10 km/h',
    String theme = 'light',
    String unit = 'celsius',
  }) async {
    await HomeWidget.saveWidgetData(_cityKey, city);
    await HomeWidget.saveWidgetData(_locationKey, location);
    await HomeWidget.saveWidgetData(_temperatureKey, temperature);
    await HomeWidget.saveWidgetData(_conditionKey, condition);
    await HomeWidget.saveWidgetData(_iconKey, icon);
    await HomeWidget.saveWidgetData(_humidityKey, humidity);
    await HomeWidget.saveWidgetData(_windKey, wind);
    await HomeWidget.saveWidgetData(_themeKey, theme);
    await HomeWidget.saveWidgetData(_unitKey, unit);

    // Update the widget
    await updateWidget();
  }
  static String mapIcon(String iconCode) {
    switch (iconCode) {
      case "01d": return "☀️"; // Clear Day
      case "01n": return "🌙"; // Clear Night
      case "02d": return "🌤️"; // Few Clouds Day
      case "02n": return "☁️"; // Night Clouds
      case "03d":
      case "03n": return "☁️";
      case "04d":
      case "04n": return "☁️";
      case "09d":
      case "09n": return "🌧️"; // Shower Rain
      case "10d":
      case "10n": return "🌦️"; // Rain
      case "11d":
      case "11n": return "⛈️"; // Thunderstorm
      case "13d":
      case "13n": return "❄️"; // Snow
      case "50d":
      case "50n": return "🌫️"; // Fog, Mist, Haze
      default: return "❓";
    }
  }
  static Future<void> updateWidget() async {
    try {
      await HomeWidget.updateWidget(
        name: 'WeatherWidgetProvider',
        androidName: 'WeatherWidgetProvider',
      );
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  static Future<void> clearConfiguration() async {
    await HomeWidget.saveWidgetData(_cityKey, null);
    await HomeWidget.saveWidgetData(_locationKey, null);
    await HomeWidget.saveWidgetData(_temperatureKey, null);
    await HomeWidget.saveWidgetData(_conditionKey, null);
    await HomeWidget.saveWidgetData(_iconKey, null);
    await HomeWidget.saveWidgetData(_humidityKey, null);
    await HomeWidget.saveWidgetData(_windKey, null);
    await HomeWidget.saveWidgetData(_themeKey, null);
    await HomeWidget.saveWidgetData(_unitKey, null);
  }

  // Check if widget is configured
  static Future<bool> isConfigured() async {
    final location = await HomeWidget.getWidgetData(_locationKey);
    return location != null && location != 'Unknown';
  }

  // Get widget data
  static Future<Map<String, dynamic>> getWidgetData() async {
    return {
      'city': await HomeWidget.getWidgetData(_cityKey, defaultValue: 'Lahore'),
      'location': await HomeWidget.getWidgetData(_locationKey, defaultValue: 'Unknown'),
      'temperature': await HomeWidget.getWidgetData(_temperatureKey, defaultValue: '--°C'),
      'condition': await HomeWidget.getWidgetData(_conditionKey, defaultValue: 'No data'),
      'icon': await HomeWidget.getWidgetData(_iconKey, defaultValue: '🌤️'),
      'humidity': await HomeWidget.getWidgetData(_humidityKey, defaultValue: '--%'),
      'wind': await HomeWidget.getWidgetData(_windKey, defaultValue: '-- km/h'),
      'theme': await HomeWidget.getWidgetData(_themeKey, defaultValue: 'light'),
      'unit': await HomeWidget.getWidgetData(_unitKey, defaultValue: 'celsius'),
    };
  }
}