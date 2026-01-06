import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ChatBotService {
  final String _apiKey = AppConstants.openRouterApiKey;
  static const String _baseUrl = "https://openrouter.ai/api/v1/chat/completions";

  // Conversation history for context-aware responses
  final List<Map<String, String>> _conversationHistory = [];
  static const int _maxHistoryLength = 10;

  // ===================================================================
  // PUBLIC ENTRY
  // ===================================================================
  Future<String> getWeatherResponse(
      String userMessage,
      String currentWeather,
      Map<String, dynamic>? weatherData,
      ) async {
    final processedMessage = userMessage.trim();

    if (processedMessage.isEmpty) {
      return "Please ask me something about the weather! 🌤️";
    }

    // Check for quick responses first (instant replies)
    final quickResponse = _handleQuickResponse(
        processedMessage.toLowerCase(),
        weatherData
    );
    if (quickResponse != null) {
      _addToHistory(processedMessage, quickResponse);
      return quickResponse;
    }

    // Use AI for complex queries
    try {
      final response = await _callOpenRouterAPI(
        processedMessage,
        currentWeather,
        weatherData,
      );
      _addToHistory(processedMessage, response);
      return response;
    } catch (e) {
      print("❌ ChatBot API Error: $e");
      return _getIntelligentFallback(processedMessage, weatherData);
    }
  }

  // ===================================================================
  // CONVERSATION HISTORY MANAGEMENT
  // ===================================================================
  void _addToHistory(String userMsg, String botMsg) {
    _conversationHistory.add({"role": "user", "content": userMsg});
    _conversationHistory.add({"role": "assistant", "content": botMsg});

    // Keep only recent messages
    if (_conversationHistory.length > _maxHistoryLength * 2) {
      _conversationHistory.removeRange(0, 2);
    }
  }

  void clearHistory() {
    _conversationHistory.clear();
  }

  // ===================================================================
  // OPENROUTER AI CALL WITH CONTEXT
  // ===================================================================
  Future<String> _callOpenRouterAPI(
      String userMessage,
      String currentWeather,
      Map<String, dynamic>? weatherData,
      ) async {
    const String model = "openai/gpt-oss-20b:free";
    const int maxTokens = 200;

    final weatherContext = _buildWeatherContext(currentWeather, weatherData);
    final systemPrompt = _createSystemPrompt(weatherContext);

    // Build messages with history
    final messages = [
      {"role": "system", "content": systemPrompt},
      ..._conversationHistory.take(_conversationHistory.length),
      {"role": "user", "content": userMessage}
    ];

    final payload = {
      "model": model,
      "messages": messages,
      "max_tokens": maxTokens,
      "temperature": 0.7,
      "top_p": 0.9,
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $_apiKey",
        "HTTP-Referer": "https://weatherwhiz.app",
        "X-Title": "WeatherWhiz AI Assistant",
      },
      body: jsonEncode(payload),
    ).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw TimeoutException('Request timed out'),
    );

    if (response.statusCode != 200) {
      print("❌ OpenRouter Error (${response.statusCode}): ${response.body}");
      throw Exception("API Error: ${response.statusCode}");
    }

    final decoded = jsonDecode(response.body);
    final text = decoded["choices"]?[0]?["message"]?["content"]?.toString() ?? "";

    if (text.trim().isEmpty) {
      throw Exception("Empty response from AI");
    }

    return _cleanAndFormatResponse(text);
  }

  // ===================================================================
  // SYSTEM PROMPT ENGINEERING
  // ===================================================================
  String _createSystemPrompt(String weatherContext) {
    return """You are WeatherWhiz, a friendly and knowledgeable meteorology assistant. 

CURRENT WEATHER DATA:
$weatherContext

YOUR PERSONALITY:
- Warm, helpful, and conversational
- Use weather emojis naturally (🌤️☀️🌧️⛅🌩️❄️🌈💨)
- Provide practical, actionable advice
- Stay focused on weather-related topics

RESPONSE GUIDELINES:
1. Keep responses concise (2-4 sentences)
2. Give specific advice based on actual conditions
3. Use Celsius for temperature
4. Reference the current weather data when relevant
5. If asked non-weather questions, politely redirect to weather topics
6. Be conversational and remember context from previous messages

EXAMPLES:
User: "Should I go for a run?"
You: "With ${weatherContext.split(',')[0]}, it's perfect for a run! 🏃 Just remember to stay hydrated and wear sunscreen if it's sunny. What time are you planning to go?"

User: "Is it going to rain?"
You: "Based on current conditions, [analyze weather data]. I'd recommend [specific advice]. Want to know about tomorrow's forecast?"

Now respond naturally to the user's question.""";
  }

  String _buildWeatherContext(String currentWeather, Map<String, dynamic>? data) {
    if (data == null) return currentWeather;

    final main = data["main"] as Map<String, dynamic>?;
    final weatherList = data["weather"] as List<dynamic>?;
    final wind = data["wind"] as Map<String, dynamic>?;
    final clouds = data["clouds"] as Map<String, dynamic>?;

    final temp = main?["temp"]?.toStringAsFixed(1) ?? "--";
    final feelsLike = main?["feels_like"]?.toStringAsFixed(1) ?? "--";
    final humidity = main?["humidity"]?.toString() ?? "--";
    final pressure = main?["pressure"]?.toString() ?? "--";
    final windSpeed = wind?["speed"]?.toStringAsFixed(1) ?? "--";
    final cloudiness = clouds?["all"]?.toString() ?? "--";
    final description = weatherList?.isNotEmpty == true
        ? weatherList!.first["description"]
        : "unknown";

    return """Temperature: $temp°C (feels like $feelsLike°C)
Conditions: $description
Humidity: $humidity%
Wind Speed: $windSpeed m/s
Cloudiness: $cloudiness%
Pressure: $pressure hPa""";
  }

  // ===================================================================
  // RESPONSE FORMATTING
  // ===================================================================
  String _cleanAndFormatResponse(String text) {
    // Remove excessive newlines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    // Remove markdown formatting if present
    text = text.replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1');
    text = text.replaceAll(RegExp(r'\*([^*]+)\*'), r'$1');

    // Limit to 4 sentences max
    final sentences = text.split(RegExp(r'(?<=[.!?])\s+'));
    if (sentences.length > 4) {
      text = sentences.take(4).join(' ');
    }

    return text.trim();
  }

  // ===================================================================
  // QUICK RESPONSES (NO API CALL NEEDED)
  // ===================================================================
  String? _handleQuickResponse(String message, Map<String, dynamic>? data) {
    // Greetings
    if (RegExp(r'^(hi|hello|hey|hola|greetings)[\s!]*$').hasMatch(message)) {
      return "Hello! 👋 I'm WeatherWhiz, your personal weather assistant. Ask me anything about the current weather or get advice for your activities! 🌤️";
    }

    if (RegExp(r'^(thanks|thank you|thx)').hasMatch(message)) {
      return "You're welcome! 🌈 Feel free to ask me anything else about the weather!";
    }

    if (message.contains("who are you") || message.contains("what are you")) {
      return "I'm WeatherWhiz! 🌦️ Your AI-powered weather assistant. I can tell you about current conditions, give activity advice, and answer all your weather questions!";
    }

    if (message.contains("bye") || message.contains("goodbye")) {
      return "Goodbye! 👋 Stay safe and enjoy the weather! Come back anytime you need weather info! 🌤️";
    }

    // Quick data lookups
    if (data != null) {
      final main = data["main"] as Map<String, dynamic>?;
      final weatherList = data["weather"] as List<dynamic>?;
      final wind = data["wind"] as Map<String, dynamic>?;

      final temp = main?["temp"]?.toStringAsFixed(1) ?? "--";
      final humidity = main?["humidity"]?.toString() ?? "--";
      final windSpeed = wind?["speed"]?.toStringAsFixed(1) ?? "--";
      final description = weatherList?.isNotEmpty == true
          ? weatherList!.first["description"]
          : "unknown";

      if (RegExp(r'\btemperature\b').hasMatch(message)) {
        final feelsLike = main?["feels_like"]?.toStringAsFixed(1) ?? "--";
        return "The temperature is $temp°C, but it feels like $feelsLike°C. 🌡️";
      }

      if (RegExp(r'\bhumidity\b').hasMatch(message)) {
        final advice = int.tryParse(humidity) != null && int.parse(humidity) > 70
            ? "That's quite humid! Stay hydrated. 💧"
            : "That's comfortable! 😊";
        return "Humidity is at $humidity%. $advice";
      }

      if (RegExp(r'\bwind\b').hasMatch(message)) {
        final windAdvice = double.tryParse(windSpeed) != null && double.parse(windSpeed) > 10
            ? "It's quite windy! 💨"
            : "Wind is calm. 🍃";
        return "Wind speed is $windSpeed m/s. $windAdvice";
      }
    }

    return null; // Let AI handle complex queries
  }

  // ===================================================================
  // INTELLIGENT FALLBACK
  // ===================================================================
  String _getIntelligentFallback(String message, Map<String, dynamic>? data) {
    if (data == null) {
      return "I'm having trouble connecting right now. 😔 But I'm here to help with weather info! Try asking about temperature, humidity, or wind conditions.";
    }

    final main = data["main"] as Map<String, dynamic>?;
    final weatherList = data["weather"] as List<dynamic>?;
    final temp = main?["temp"]?.toStringAsFixed(1) ?? "--";
    final description = weatherList?.isNotEmpty == true
        ? weatherList!.first["description"]
        : "unknown";

    // Try to give a relevant response based on keywords
    if (message.toLowerCase().contains("rain")) {
      final hasRain = description.toLowerCase().contains("rain");
      return hasRain
          ? "Yes, it's currently raining. ${_getRainAdvice()} 🌧️"
          : "No rain right now! It's $description with $temp°C. ☀️";
    }

    if (message.toLowerCase().contains("hot") || message.toLowerCase().contains("cold")) {
      return _getTemperatureAdvice(double.tryParse(temp) ?? 20);
    }

    return "Currently it's $temp°C with $description. 🌤️ What would you like to know more about?";
  }

  // ===================================================================
  // UTILITY HELPERS
  // ===================================================================
  String _getRainAdvice() {
    return "Don't forget your umbrella! ☔ Indoor activities would be great today.";
  }

  String _getTemperatureAdvice(double temp) {
    if (temp < 0) {
      return "It's freezing at ${temp.toStringAsFixed(1)}°C! ❄️ Bundle up warm and stay safe!";
    } else if (temp < 10) {
      return "It's quite cold at ${temp.toStringAsFixed(1)}°C. 🧥 Wear a warm jacket!";
    } else if (temp < 20) {
      return "It's cool at ${temp.toStringAsFixed(1)}°C. 🍂 A light jacket should be perfect!";
    } else if (temp < 28) {
      return "It's pleasant at ${temp.toStringAsFixed(1)}°C! 🌤️ Great weather for outdoor activities!";
    } else if (temp < 35) {
      return "It's hot at ${temp.toStringAsFixed(1)}°C! ☀️ Stay hydrated and wear sunscreen!";
    } else {
      return "It's extremely hot at ${temp.toStringAsFixed(1)}°C! 🥵 Stay indoors if possible and drink plenty of water!";
    }
  }
}