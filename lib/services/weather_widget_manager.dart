import 'package:home_widget/home_widget.dart';
import 'package:weather_app/widgets/weather_widget_provider.dart';
import 'package:weather_app/screens/widget_configuration_screen.dart';
import 'package:weather_app/services/weather_service.dart';


class WeatherWidgetManager {
  static Future<void> initialize() async {
    // Initialize widget with default data if not already configured
    final isConfigured = await WeatherWidgetProvider.isConfigured();
    if (!isConfigured) {
      await WeatherWidgetProvider.configureWidget();
    }
    print('✅ Weather Widget Manager initialized');
  }


  static Future<void> updateWidgetWithCity(String cityName) async {
    try {
      print("🔄 Updating widget for city: $cityName");

      // 1️⃣ Fetch actual weather data
      final weather = await WeatherService().byCity(cityName);

      print("🌤 API Weather Data: $weather");

      final main = weather["main"];
      final weatherList = weather["weather"][0];

      final tempValue = (main["temp"] is num)
          ? (main["temp"] as num).round()
          : int.tryParse(main["temp"].toString())?.round() ?? 0;

      final temp = "$tempValue°C";

      final condition = weatherList["description"];
      final icon = WeatherWidgetProvider.mapIcon(weatherList["icon"]);
      final humidity = "${main["humidity"]}%";
      final wind = "${weather["wind"]["speed"]} km/h";

      print("🌡 Temp: $temp, ☁ Condition: $condition, 💧 Humidity: $humidity, 💨 Wind: $wind");

      // 2️⃣ Update widget with REAL DATA
      await WeatherWidgetProvider.configureWidget(
        city: cityName,
        location: cityName,
        temperature: temp,
        condition: condition,
        icon: icon,
        humidity: humidity,
        wind: wind,
      );

      print("✅ Widget updated successfully!");
    } catch (e) {
      print("❌ Error updating widget: $e");
    }
  }

  static Future<bool> isWidgetActive() async {
    try {
      final widgets = await HomeWidget.getInstalledWidgets();
      return widgets.isNotEmpty;
    } catch (e) {
      print('Error checking widget status: $e');
      return false;
    }
  }


  static Future<Map<String, dynamic>> getCurrentWidgetData() async {
    return await WeatherWidgetProvider.getWidgetData();
  }
}