import '../config/api_keys.dart'; // Import from config

class AppConstants {
  // Use keys from config file
  static const openWeatherApiKey = ApiKeys.openWeatherApiKey;
  static const openRouterApiKey = ApiKeys.openRouterApiKey;

  static const baseWeatherUrl = 'https://api.openweathermap.org/data/2.5/weather';
  static const defaultUnits = 'metric';
}